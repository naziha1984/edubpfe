# PIN 功能测试指南

## 功能概述

- **PUT /api/kids/:kidId/pin**: 设置/更新 kid 的 PIN（需要 parent 认证）
- **POST /api/kids/:kidId/verify-pin**: 验证 PIN 并获取 kidToken
- **PIN 锁定机制**: 5 次失败后锁定 10 分钟
- **kidToken**: JWT token，类型 KID_SESSION，有效期 30 分钟
- **KidAuthGuard**: 用于保护 kid 路由

## 前置要求

1. 安装依赖: `npm install`
2. 运行 seed script: `npm run seed`
3. 启动服务器: `npm run start:dev`
4. 注册 parent 用户并创建 kid

## API 端点

### 1. PUT /api/kids/:kidId/pin

设置或更新 kid 的 PIN（需要 parent 认证）

**请求:**
```bash
curl -X PUT http://localhost:3000/api/kids/KID_ID/pin \
  -H "Authorization: Bearer PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pin": "1234"
  }'
```

**预期响应:**
```json
{
  "message": "PIN set successfully"
}
```

**验证规则:**
- PIN 必须是 4 位数字
- 需要 parent 认证
- 需要 ownership check（只能设置自己 kid 的 PIN）

### 2. POST /api/kids/:kidId/verify-pin

验证 PIN 并获取 kidToken

**请求:**
```bash
curl -X POST http://localhost:3000/api/kids/KID_ID/verify-pin \
  -H "Content-Type: application/json" \
  -d '{
    "pin": "1234"
  }'
```

**成功响应:**
```json
{
  "kidToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": "30m"
}
```

**失败响应 (401):**
```json
{
  "statusCode": 401,
  "message": "Invalid PIN",
  "timestamp": "...",
  "path": "/api/kids/.../verify-pin",
  "method": "POST"
}
```

**锁定响应 (429):**
```json
{
  "statusCode": 429,
  "message": "PIN is locked. Try again in 10 minute(s)",
  "timestamp": "...",
  "path": "/api/kids/.../verify-pin",
  "method": "POST"
}
```

## 完整测试流程

### 步骤 1: 注册 Parent 并创建 Kid

```bash
# 注册 Parent
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "parent@example.com",
    "password": "password123",
    "firstName": "Parent",
    "lastName": "One"
  }'

# 保存 PARENT_TOKEN

# 创建 Kid
curl -X POST http://localhost:3000/api/kids \
  -H "Authorization: Bearer $PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Alice",
    "lastName": "Smith",
    "dateOfBirth": "2015-05-15",
    "grade": "3rd Grade"
  }'

# 保存 KID_ID
```

### 步骤 2: 设置 PIN

```bash
curl -X PUT http://localhost:3000/api/kids/$KID_ID/pin \
  -H "Authorization: Bearer $PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pin": "1234"
  }'
```

**验证:** 应该返回成功消息

### 步骤 3: 验证 PIN（正确）

```bash
curl -X POST http://localhost:3000/api/kids/$KID_ID/verify-pin \
  -H "Content-Type: application/json" \
  -d '{
    "pin": "1234"
  }'
```

**验证:** 应该返回 kidToken

### 步骤 4: 验证 PIN（错误）

```bash
curl -X POST http://localhost:3000/api/kids/$KID_ID/verify-pin \
  -H "Content-Type: application/json" \
  -d '{
    "pin": "9999"
  }'
```

**验证:** 应该返回 401 Unauthorized

### 步骤 5: 测试锁定机制

连续 5 次输入错误 PIN：

```bash
# 尝试 1-4 次（应该返回 401）
for i in {1..4}; do
  curl -X POST http://localhost:3000/api/kids/$KID_ID/verify-pin \
    -H "Content-Type: application/json" \
    -d '{"pin": "9999"}'
  echo ""
done

# 第 5 次尝试（应该锁定）
curl -X POST http://localhost:3000/api/kids/$KID_ID/verify-pin \
  -H "Content-Type: application/json" \
  -d '{
    "pin": "9999"
  }'
```

**验证:** 第 5 次应该返回 429 Too Many Requests，提示锁定 10 分钟

### 步骤 6: 测试锁定期间

在锁定期间尝试验证 PIN：

```bash
curl -X POST http://localhost:3000/api/kids/$KID_ID/verify-pin \
  -H "Content-Type: application/json" \
  -d '{
    "pin": "1234"
  }'
```

**验证:** 即使 PIN 正确，也应该返回 429（锁定中）

### 步骤 7: 使用 kidToken

使用获取的 kidToken 访问受 KidAuthGuard 保护的路由：

```bash
# 获取 kid 信息
curl -X GET http://localhost:3000/api/kid-demo/me \
  -H "Authorization: Bearer $KID_TOKEN"

# 访问受保护的路由
curl -X GET http://localhost:3000/api/kid-demo/protected \
  -H "Authorization: Bearer $KID_TOKEN"
```

**预期响应:**
```json
{
  "message": "Hello Alice Smith!",
  "kidId": "...",
  "firstName": "Alice",
  "lastName": "Smith",
  "parentId": "..."
}
```

## Windows PowerShell 测试脚本

```powershell
$BASE_URL = "http://localhost:3000/api"

# 1. 注册 Parent
Write-Host "1. Registering Parent..." -ForegroundColor Yellow
$parentBody = @{
    email = "parent@example.com"
    password = "password123"
    firstName = "Parent"
    lastName = "One"
} | ConvertTo-Json

$parentResponse = Invoke-RestMethod -Uri "$BASE_URL/auth/register" `
    -Method Post `
    -ContentType "application/json" `
    -Body $parentBody

$PARENT_TOKEN = $parentResponse.access_token
Write-Host "Parent Token: $($PARENT_TOKEN.Substring(0, 50))..." -ForegroundColor Gray

# 2. 创建 Kid
Write-Host "`n2. Creating Kid..." -ForegroundColor Yellow
$kidBody = @{
    firstName = "Alice"
    lastName = "Smith"
    dateOfBirth = "2015-05-15"
    grade = "3rd Grade"
} | ConvertTo-Json

$parentHeaders = @{
    Authorization = "Bearer $PARENT_TOKEN"
}

$kidResponse = Invoke-RestMethod -Uri "$BASE_URL/kids" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $parentHeaders `
    -Body $kidBody

$KID_ID = $kidResponse.id
Write-Host "Kid ID: $KID_ID" -ForegroundColor Green

# 3. 设置 PIN
Write-Host "`n3. Setting PIN..." -ForegroundColor Yellow
$pinBody = @{
    pin = "1234"
} | ConvertTo-Json

$setPinResponse = Invoke-RestMethod -Uri "$BASE_URL/kids/$KID_ID/pin" `
    -Method Put `
    -ContentType "application/json" `
    -Headers $parentHeaders `
    -Body $pinBody

Write-Host "✅ PIN set successfully" -ForegroundColor Green
$setPinResponse | ConvertTo-Json

# 4. 验证 PIN（正确）
Write-Host "`n4. Verifying PIN (correct)..." -ForegroundColor Yellow
$verifyBody = @{
    pin = "1234"
} | ConvertTo-Json

$verifyResponse = Invoke-RestMethod -Uri "$BASE_URL/kids/$KID_ID/verify-pin" `
    -Method Post `
    -ContentType "application/json" `
    -Body $verifyBody

$KID_TOKEN = $verifyResponse.kidToken
Write-Host "✅ PIN verified, kidToken received" -ForegroundColor Green
Write-Host "Kid Token: $($KID_TOKEN.Substring(0, 50))..." -ForegroundColor Gray

# 5. 验证 PIN（错误）
Write-Host "`n5. Verifying PIN (incorrect)..." -ForegroundColor Yellow
$wrongPinBody = @{
    pin = "9999"
} | ConvertTo-Json

try {
    $wrongResponse = Invoke-RestMethod -Uri "$BASE_URL/kids/$KID_ID/verify-pin" `
        -Method Post `
        -ContentType "application/json" `
        -Body $wrongPinBody
    
    Write-Host "❌ Should have failed" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✅ Correctly rejected invalid PIN (401)" -ForegroundColor Green
    } else {
        Write-Host "❌ Unexpected error" -ForegroundColor Red
    }
}

# 6. 测试锁定机制（5 次失败）
Write-Host "`n6. Testing lock mechanism (5 failed attempts)..." -ForegroundColor Yellow
for ($i = 1; $i -le 5; $i++) {
    Write-Host "Attempt $i..." -ForegroundColor Gray
    try {
        $lockTestResponse = Invoke-RestMethod -Uri "$BASE_URL/kids/$KID_ID/verify-pin" `
            -Method Post `
            -ContentType "application/json" `
            -Body $wrongPinBody
        
        Write-Host "❌ Should have failed" -ForegroundColor Red
    } catch {
        if ($i -lt 5) {
            if ($_.Exception.Response.StatusCode -eq 401) {
                Write-Host "  Attempt $i failed (401) - as expected" -ForegroundColor Yellow
            }
        } else {
            if ($_.Exception.Response.StatusCode -eq 429) {
                Write-Host "✅ PIN locked after 5 attempts (429)" -ForegroundColor Green
            } else {
                Write-Host "❌ Expected 429, got $($_.Exception.Response.StatusCode)" -ForegroundColor Red
            }
        }
    }
    Start-Sleep -Seconds 1
}

Write-Host "`n✅ All tests completed!" -ForegroundColor Green
```

## 测试场景清单

- [ ] Parent 可以设置 kid 的 PIN
- [ ] Parent 只能设置自己 kid 的 PIN（ownership check）
- [ ] PIN 必须是 4 位数字（验证失败）
- [ ] 正确 PIN 验证成功并返回 kidToken
- [ ] 错误 PIN 验证失败（401）
- [ ] 5 次失败后 PIN 被锁定（429）
- [ ] 锁定期间即使正确 PIN 也无法验证（429）
- [ ] kidToken 是有效的 JWT
- [ ] kidToken 包含正确的 payload（type: KID_SESSION）
- [ ] kidToken 有效期 30 分钟
- [ ] KidAuthGuard 可以验证 kidToken

## 错误场景测试

### 1. PIN 未设置
```bash
# 尝试验证未设置 PIN 的 kid
curl -X POST http://localhost:3000/api/kids/KID_ID/verify-pin \
  -H "Content-Type: application/json" \
  -d '{"pin": "1234"}'
```
**预期:** 400 Bad Request - "PIN not set for this kid"

### 2. 无效 PIN 格式
```bash
# 设置非 4 位数字 PIN
curl -X PUT http://localhost:3000/api/kids/KID_ID/pin \
  -H "Authorization: Bearer PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"pin": "12345"}'
```
**预期:** 400 Bad Request - "PIN must be exactly 4 digits"

### 3. 未认证设置 PIN
```bash
curl -X PUT http://localhost:3000/api/kids/KID_ID/pin \
  -H "Content-Type: application/json" \
  -d '{"pin": "1234"}'
```
**预期:** 401 Unauthorized

### 4. 其他 Parent 设置 PIN
```bash
# 使用其他 parent 的 token
curl -X PUT http://localhost:3000/api/kids/KID_ID/pin \
  -H "Authorization: Bearer OTHER_PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"pin": "1234"}'
```
**预期:** 403 Forbidden

## kidToken 使用

kidToken 可以用于访问受 KidAuthGuard 保护的路由：

```typescript
@Get('kid-protected')
@UseGuards(KidAuthGuard)
async kidProtected(@GetKid() kid: any) {
  return {
    message: `Hello ${kid.firstName}!`,
    kidId: kid.kidId,
  };
}
```

## 注意事项

1. **PIN 存储**: PIN 使用 bcrypt 加密存储（10 rounds）
2. **锁定时间**: 5 次失败后锁定 10 分钟
3. **失败计数**: 每次失败增加计数，成功验证后重置
4. **kidToken 有效期**: 30 分钟
5. **kidToken 类型**: KID_SESSION（用于区分普通 JWT）
6. **自动重置**: 成功验证 PIN 后，失败计数和锁定时间都会重置
