# KidsModule 测试指南

## 前置要求

1. 安装依赖: `npm install`
2. 运行 seed script: `npm run seed`
3. 启动服务器: `npm run start:dev`
4. 注册至少两个 PARENT 用户用于测试 ownership

## 测试场景

### 场景 1: Parent 1 创建和管理自己的 Kids

### 场景 2: Parent 2 创建和管理自己的 Kids

### 场景 3: Ownership 验证（Parent 1 不能访问 Parent 2 的 Kids）

## API 端点

所有端点都需要 JWT 认证，并且只允许 PARENT 角色访问。

### 1. GET /api/kids

获取当前登录 parent 的所有 kids

**请求:**
```bash
curl -X GET http://localhost:3000/api/kids \
  -H "Authorization: Bearer PARENT_TOKEN"
```

**预期响应:**
```json
[
  {
    "id": "...",
    "firstName": "Alice",
    "lastName": "Smith",
    "dateOfBirth": "2015-05-15T00:00:00.000Z",
    "grade": "3rd Grade",
    "school": "Elementary School",
    "isActive": true,
    "parentId": "...",
    "createdAt": "...",
    "updatedAt": "..."
  }
]
```

### 2. POST /api/kids

创建新的 kid（自动关联到当前 parent）

**请求:**
```bash
curl -X POST http://localhost:3000/api/kids \
  -H "Authorization: Bearer PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Alice",
    "lastName": "Smith",
    "dateOfBirth": "2015-05-15",
    "grade": "3rd Grade",
    "school": "Elementary School"
  }'
```

**预期响应:**
```json
{
  "id": "...",
  "firstName": "Alice",
  "lastName": "Smith",
  "dateOfBirth": "2015-05-15T00:00:00.000Z",
  "grade": "3rd Grade",
  "school": "Elementary School",
  "isActive": true,
  "parentId": "...",
  "createdAt": "...",
  "updatedAt": "..."
}
```

### 3. PUT /api/kids/:kidId

更新 kid（需要 ownership check）

**请求:**
```bash
curl -X PUT http://localhost:3000/api/kids/KID_ID \
  -H "Authorization: Bearer PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Alice Updated",
    "grade": "4th Grade"
  }'
```

**预期响应:**
```json
{
  "id": "...",
  "firstName": "Alice Updated",
  "lastName": "Smith",
  "dateOfBirth": "2015-05-15T00:00:00.000Z",
  "grade": "4th Grade",
  "school": "Elementary School",
  "isActive": true,
  "parentId": "...",
  "createdAt": "...",
  "updatedAt": "..."
}
```

### 4. DELETE /api/kids/:kidId

删除 kid（需要 ownership check）

**请求:**
```bash
curl -X DELETE http://localhost:3000/api/kids/KID_ID \
  -H "Authorization: Bearer PARENT_TOKEN"
```

**预期响应:** 204 No Content

## 完整测试流程

### 步骤 1: 注册两个 Parent 用户

```bash
# 注册 Parent 1
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "parent1@example.com",
    "password": "password123",
    "firstName": "Parent",
    "lastName": "One"
  }'

# 保存 Parent 1 的 token
# PARENT1_TOKEN="..."

# 注册 Parent 2
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "parent2@example.com",
    "password": "password123",
    "firstName": "Parent",
    "lastName": "Two"
  }'

# 保存 Parent 2 的 token
# PARENT2_TOKEN="..."
```

### 步骤 2: Parent 1 创建 Kid

```bash
curl -X POST http://localhost:3000/api/kids \
  -H "Authorization: Bearer $PARENT1_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Alice",
    "lastName": "One",
    "dateOfBirth": "2015-05-15",
    "grade": "3rd Grade",
    "school": "Elementary School"
  }'

# 保存 Kid ID
# KID1_ID="..."
```

### 步骤 3: Parent 1 查看自己的 Kids

```bash
curl -X GET http://localhost:3000/api/kids \
  -H "Authorization: Bearer $PARENT1_TOKEN"
```

**验证:** 应该看到 Parent 1 创建的 kid

### 步骤 4: Parent 2 创建 Kid

```bash
curl -X POST http://localhost:3000/api/kids \
  -H "Authorization: Bearer $PARENT2_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Bob",
    "lastName": "Two",
    "dateOfBirth": "2016-06-20",
    "grade": "2nd Grade",
    "school": "Elementary School"
  }'

# 保存 Kid ID
# KID2_ID="..."
```

### 步骤 5: Parent 2 查看自己的 Kids

```bash
curl -X GET http://localhost:3000/api/kids \
  -H "Authorization: Bearer $PARENT2_TOKEN"
```

**验证:** 应该只看到 Parent 2 创建的 kid，看不到 Parent 1 的 kid

### 步骤 6: Ownership 测试 - Parent 1 尝试访问 Parent 2 的 Kid

```bash
# Parent 1 尝试更新 Parent 2 的 kid（应该失败）
curl -X PUT http://localhost:3000/api/kids/$KID2_ID \
  -H "Authorization: Bearer $PARENT1_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Hacked"
  }'
```

**预期响应 (403 Forbidden):**
```json
{
  "statusCode": 403,
  "message": "You do not have permission to update this kid",
  "timestamp": "...",
  "path": "/api/kids/...",
  "method": "PUT"
}
```

### 步骤 7: Ownership 测试 - Parent 1 尝试删除 Parent 2 的 Kid

```bash
curl -X DELETE http://localhost:3000/api/kids/$KID2_ID \
  -H "Authorization: Bearer $PARENT1_TOKEN"
```

**预期响应 (403 Forbidden):**
```json
{
  "statusCode": 403,
  "message": "You do not have permission to delete this kid",
  "timestamp": "...",
  "path": "/api/kids/...",
  "method": "DELETE"
}
```

### 步骤 8: Parent 1 更新自己的 Kid

```bash
curl -X PUT http://localhost:3000/api/kids/$KID1_ID \
  -H "Authorization: Bearer $PARENT1_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Alice Updated",
    "grade": "4th Grade"
  }'
```

**验证:** 应该成功更新

### 步骤 9: Parent 1 删除自己的 Kid

```bash
curl -X DELETE http://localhost:3000/api/kids/$KID1_ID \
  -H "Authorization: Bearer $PARENT1_TOKEN"
```

**验证:** 应该成功删除（204 No Content）

### 步骤 10: 验证 Kid 已删除

```bash
curl -X GET http://localhost:3000/api/kids \
  -H "Authorization: Bearer $PARENT1_TOKEN"
```

**验证:** 应该返回空数组

## Windows PowerShell 测试脚本

```powershell
$BASE_URL = "http://localhost:3000/api"

# 1. 注册 Parent 1
Write-Host "1. Registering Parent 1..." -ForegroundColor Yellow
$parent1Body = @{
    email = "parent1@example.com"
    password = "password123"
    firstName = "Parent"
    lastName = "One"
} | ConvertTo-Json

$parent1Response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" `
    -Method Post `
    -ContentType "application/json" `
    -Body $parent1Body

$PARENT1_TOKEN = $parent1Response.access_token
Write-Host "Parent 1 Token: $($PARENT1_TOKEN.Substring(0, 50))..." -ForegroundColor Gray

# 2. 注册 Parent 2
Write-Host "`n2. Registering Parent 2..." -ForegroundColor Yellow
$parent2Body = @{
    email = "parent2@example.com"
    password = "password123"
    firstName = "Parent"
    lastName = "Two"
} | ConvertTo-Json

$parent2Response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" `
    -Method Post `
    -ContentType "application/json" `
    -Body $parent2Body

$PARENT2_TOKEN = $parent2Response.access_token
Write-Host "Parent 2 Token: $($PARENT2_TOKEN.Substring(0, 50))..." -ForegroundColor Gray

# 3. Parent 1 创建 Kid
Write-Host "`n3. Parent 1 creating kid..." -ForegroundColor Yellow
$kid1Body = @{
    firstName = "Alice"
    lastName = "One"
    dateOfBirth = "2015-05-15"
    grade = "3rd Grade"
    school = "Elementary School"
} | ConvertTo-Json

$parent1Headers = @{
    Authorization = "Bearer $PARENT1_TOKEN"
}

$kid1Response = Invoke-RestMethod -Uri "$BASE_URL/kids" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $parent1Headers `
    -Body $kid1Body

$KID1_ID = $kid1Response.id
Write-Host "Kid 1 ID: $KID1_ID" -ForegroundColor Green

# 4. Parent 1 查看自己的 Kids
Write-Host "`n4. Parent 1 viewing own kids..." -ForegroundColor Yellow
$parent1Kids = Invoke-RestMethod -Uri "$BASE_URL/kids" `
    -Method Get `
    -Headers $parent1Headers

Write-Host "Parent 1 has $($parent1Kids.Count) kid(s)" -ForegroundColor Green
$parent1Kids | ConvertTo-Json

# 5. Parent 2 创建 Kid
Write-Host "`n5. Parent 2 creating kid..." -ForegroundColor Yellow
$kid2Body = @{
    firstName = "Bob"
    lastName = "Two"
    dateOfBirth = "2016-06-20"
    grade = "2nd Grade"
    school = "Elementary School"
} | ConvertTo-Json

$parent2Headers = @{
    Authorization = "Bearer $PARENT2_TOKEN"
}

$kid2Response = Invoke-RestMethod -Uri "$BASE_URL/kids" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $parent2Headers `
    -Body $kid2Body

$KID2_ID = $kid2Response.id
Write-Host "Kid 2 ID: $KID2_ID" -ForegroundColor Green

# 6. Parent 2 查看自己的 Kids
Write-Host "`n6. Parent 2 viewing own kids..." -ForegroundColor Yellow
$parent2Kids = Invoke-RestMethod -Uri "$BASE_URL/kids" `
    -Method Get `
    -Headers $parent2Headers

Write-Host "Parent 2 has $($parent2Kids.Count) kid(s)" -ForegroundColor Green
$parent2Kids | ConvertTo-Json

# 7. Ownership 测试 - Parent 1 尝试更新 Parent 2 的 Kid
Write-Host "`n7. Testing ownership - Parent 1 trying to update Parent 2's kid..." -ForegroundColor Yellow
try {
    $updateBody = @{
        firstName = "Hacked"
    } | ConvertTo-Json

    Invoke-RestMethod -Uri "$BASE_URL/kids/$KID2_ID" `
        -Method Put `
        -ContentType "application/json" `
        -Headers $parent1Headers `
        -Body $updateBody
    
    Write-Host "❌ Ownership check failed!" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 403) {
        Write-Host "✅ Ownership check passed (403 Forbidden)" -ForegroundColor Green
    } else {
        Write-Host "❌ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 8. Ownership 测试 - Parent 1 尝试删除 Parent 2 的 Kid
Write-Host "`n8. Testing ownership - Parent 1 trying to delete Parent 2's kid..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "$BASE_URL/kids/$KID2_ID" `
        -Method Delete `
        -Headers $parent1Headers
    
    Write-Host "❌ Ownership check failed!" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 403) {
        Write-Host "✅ Ownership check passed (403 Forbidden)" -ForegroundColor Green
    } else {
        Write-Host "❌ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n✅ All tests completed!" -ForegroundColor Green
```

## 测试验证清单

- [ ] Parent 1 可以创建 kid
- [ ] Parent 1 只能看到自己的 kids
- [ ] Parent 2 可以创建 kid
- [ ] Parent 2 只能看到自己的 kids
- [ ] Parent 1 不能看到 Parent 2 的 kids
- [ ] Parent 1 不能更新 Parent 2 的 kid (403)
- [ ] Parent 1 不能删除 Parent 2 的 kid (403)
- [ ] Parent 1 可以更新自己的 kid
- [ ] Parent 1 可以删除自己的 kid
- [ ] 删除后，kid 不再出现在列表中

## 错误场景测试

### 1. 未认证请求
```bash
curl -X GET http://localhost:3000/api/kids
```
**预期:** 401 Unauthorized

### 2. 非 PARENT 角色访问
```bash
# 使用 ADMIN token（应该失败）
curl -X GET http://localhost:3000/api/kids \
  -H "Authorization: Bearer ADMIN_TOKEN"
```
**预期:** 403 Forbidden

### 3. 访问不存在的 Kid
```bash
curl -X PUT http://localhost:3000/api/kids/nonexistent \
  -H "Authorization: Bearer PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"firstName": "Test"}'
```
**预期:** 404 Not Found

### 4. 访问其他 Parent 的 Kid
```bash
# Parent 1 尝试访问 Parent 2 的 kid
curl -X GET http://localhost:3000/api/kids/PARENT2_KID_ID \
  -H "Authorization: Bearer PARENT1_TOKEN"
```
**注意:** GET 端点不直接暴露单个 kid，但通过 GET /kids 列表，parent 只能看到自己的 kids。

## 注意事项

1. **所有端点都需要 JWT 认证**
2. **只有 PARENT 角色可以访问**
3. **GET /kids 自动过滤，只返回当前 parent 的 kids**
4. **PUT 和 DELETE 操作都包含 ownership check**
5. **parentId 在创建时自动设置为当前登录用户**
6. **不能通过 API 修改 parentId**
