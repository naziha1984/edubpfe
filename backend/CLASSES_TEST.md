# ClassesModule 测试指南

## 功能概述

### Teacher 端点（需要 TEACHER 角色）
- **POST /api/teacher/classes**: 创建班级（返回 classCode）
- **GET /api/teacher/classes**: 获取教师的所有班级
- **GET /api/teacher/classes/:classId**: 获取班级详情（仅所有者）

### Parent 端点（需要 PARENT 角色）
- **POST /api/classes/join**: 加入班级（需要 classCode 和 kidId，严格所有权检查）

## 前置要求

1. 安装依赖: `npm install`
2. 运行 seed script: `npm run seed` (创建 TEACHER 用户)
3. 启动服务器: `npm run start:dev`

## 测试流程

### 步骤 1: 准备数据

#### 1.1 登录 TEACHER

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teacher@edubridge.com",
    "password": "teacher123"
  }'
```

**保存 TEACHER_TOKEN**

#### 1.2 注册 Parent 并创建 Kid

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
    "lastName": "Smith"
  }'

# 保存 KID_ID
```

### 步骤 2: Teacher 创建班级

```bash
curl -X POST http://localhost:3000/api/teacher/classes \
  -H "Authorization: Bearer $TEACHER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Math Class 2024",
    "description": "Advanced Mathematics"
  }'
```

**预期响应:**
```json
{
  "id": "...",
  "name": "Math Class 2024",
  "description": "Advanced Mathematics",
  "classCode": "ABC123",
  "teacherId": "...",
  "isActive": true,
  "createdAt": "...",
  "updatedAt": "..."
}
```

**保存 CLASS_ID 和 CLASS_CODE**

### 步骤 3: Teacher 获取所有班级

```bash
curl -X GET http://localhost:3000/api/teacher/classes \
  -H "Authorization: Bearer $TEACHER_TOKEN"
```

**预期响应:**
```json
[
  {
    "id": "...",
    "name": "Math Class 2024",
    "description": "Advanced Mathematics",
    "classCode": "ABC123",
    "teacherId": "...",
    "isActive": true,
    "createdAt": "...",
    "updatedAt": "..."
  }
]
```

### 步骤 4: Teacher 获取班级详情

```bash
curl -X GET http://localhost:3000/api/teacher/classes/$CLASS_ID \
  -H "Authorization: Bearer $TEACHER_TOKEN"
```

**预期响应:**
```json
{
  "id": "...",
  "name": "Math Class 2024",
  "description": "Advanced Mathematics",
  "classCode": "ABC123",
  "teacherId": "...",
  "isActive": true,
  "members": [],
  "createdAt": "...",
  "updatedAt": "..."
}
```

### 步骤 5: Parent 加入班级

```bash
curl -X POST http://localhost:3000/api/classes/join \
  -H "Authorization: Bearer $PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "classCode": "CLASS_CODE",
    "kidId": "KID_ID"
  }'
```

**预期响应:**
```json
{
  "id": "...",
  "classId": "...",
  "kidId": "...",
  "isActive": true,
  "joinedAt": "..."
}
```

### 步骤 6: 验证成员已添加

```bash
curl -X GET http://localhost:3000/api/teacher/classes/$CLASS_ID \
  -H "Authorization: Bearer $TEACHER_TOKEN"
```

**预期响应应包含 members 数组:**
```json
{
  "id": "...",
  "name": "Math Class 2024",
  "members": [
    {
      "id": "...",
      "kidId": "...",
      "kid": {
        "firstName": "Alice",
        "lastName": "Smith"
      },
      "isActive": true,
      "joinedAt": "..."
    }
  ]
}
```

## 所有权检查测试

### 测试 1: Teacher 尝试查看其他 Teacher 的班级

```bash
# 创建第二个 Teacher
# 使用 Teacher 1 的 token 查看 Teacher 2 的班级
curl -X GET http://localhost:3000/api/teacher/classes/TEACHER2_CLASS_ID \
  -H "Authorization: Bearer $TEACHER1_TOKEN"
```

**预期响应 (403 Forbidden):**
```json
{
  "statusCode": 403,
  "message": "You can only view your own classes"
}
```

### 测试 2: Parent 尝试为其他 Parent 的 kid 加入班级

```bash
# 使用 Parent 1 的 token，但 kidId 属于 Parent 2
curl -X POST http://localhost:3000/api/classes/join \
  -H "Authorization: Bearer $PARENT1_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "classCode": "CLASS_CODE",
    "kidId": "PARENT2_KID_ID"
  }'
```

**预期响应 (403 Forbidden):**
```json
{
  "statusCode": 403,
  "message": "You can only join classes for your own kids"
}
```

### 测试 3: 重复加入班级

```bash
# 尝试再次加入同一个班级
curl -X POST http://localhost:3000/api/classes/join \
  -H "Authorization: Bearer $PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "classCode": "CLASS_CODE",
    "kidId": "KID_ID"
  }'
```

**预期响应 (409 Conflict):**
```json
{
  "statusCode": 409,
  "message": "Kid is already a member of this class"
}
```

### 测试 4: 无效的 classCode

```bash
curl -X POST http://localhost:3000/api/classes/join \
  -H "Authorization: Bearer $PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "classCode": "INVALID",
    "kidId": "KID_ID"
  }'
```

**预期响应 (404 Not Found):**
```json
{
  "statusCode": 404,
  "message": "Class not found or inactive"
}
```

## 完整测试脚本 (PowerShell)

```powershell
$BASE_URL = "http://localhost:3000/api"

# 1. 登录 TEACHER
Write-Host "1. Logging in as TEACHER..." -ForegroundColor Yellow
$teacherLogin = @{
    email = "teacher@edubridge.com"
    password = "teacher123"
} | ConvertTo-Json

$teacherResponse = Invoke-RestMethod -Uri "$BASE_URL/auth/login" `
    -Method Post `
    -ContentType "application/json" `
    -Body $teacherLogin

$TEACHER_TOKEN = $teacherResponse.access_token
Write-Host "Teacher Token received" -ForegroundColor Green

# 2. 创建班级
Write-Host "`n2. Creating class..." -ForegroundColor Yellow
$teacherHeaders = @{
    Authorization = "Bearer $TEACHER_TOKEN"
}

$classBody = @{
    name = "Math Class 2024"
    description = "Advanced Mathematics"
} | ConvertTo-Json

$classResponse = Invoke-RestMethod -Uri "$BASE_URL/teacher/classes" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $teacherHeaders `
    -Body $classBody

$CLASS_ID = $classResponse.id
$CLASS_CODE = $classResponse.classCode
Write-Host "Class ID: $CLASS_ID" -ForegroundColor Green
Write-Host "Class Code: $CLASS_CODE" -ForegroundColor Green
$classResponse | ConvertTo-Json

# 3. 获取所有班级
Write-Host "`n3. Getting all classes..." -ForegroundColor Yellow
$classes = Invoke-RestMethod -Uri "$BASE_URL/teacher/classes" `
    -Method Get `
    -Headers $teacherHeaders

Write-Host "Found $($classes.Count) class(es)" -ForegroundColor Green
$classes | ConvertTo-Json

# 4. 获取班级详情
Write-Host "`n4. Getting class details..." -ForegroundColor Yellow
$classDetails = Invoke-RestMethod -Uri "$BASE_URL/teacher/classes/$CLASS_ID" `
    -Method Get `
    -Headers $teacherHeaders

Write-Host "Class has $($classDetails.members.Count) member(s)" -ForegroundColor Green
$classDetails | ConvertTo-Json

# 5. 注册 Parent 并创建 Kid
Write-Host "`n5. Registering parent and creating kid..." -ForegroundColor Yellow
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

$parentHeaders = @{
    Authorization = "Bearer $PARENT_TOKEN"
}

$kidBody = @{
    firstName = "Alice"
    lastName = "Smith"
} | ConvertTo-Json

$kidResponse = Invoke-RestMethod -Uri "$BASE_URL/kids" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $parentHeaders `
    -Body $kidBody

$KID_ID = $kidResponse.id
Write-Host "Kid ID: $KID_ID" -ForegroundColor Green

# 6. Parent 加入班级
Write-Host "`n6. Parent joining class..." -ForegroundColor Yellow
$joinBody = @{
    classCode = $CLASS_CODE
    kidId = $KID_ID
} | ConvertTo-Json

$joinResponse = Invoke-RestMethod -Uri "$BASE_URL/classes/join" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $parentHeaders `
    -Body $joinBody

Write-Host "Successfully joined class" -ForegroundColor Green
$joinResponse | ConvertTo-Json

# 7. 验证成员已添加
Write-Host "`n7. Verifying member added..." -ForegroundColor Yellow
$classDetailsUpdated = Invoke-RestMethod -Uri "$BASE_URL/teacher/classes/$CLASS_ID" `
    -Method Get `
    -Headers $teacherHeaders

Write-Host "Class now has $($classDetailsUpdated.members.Count) member(s)" -ForegroundColor Green
$classDetailsUpdated.members | ConvertTo-Json

# 8. 测试所有权 - Parent 尝试为其他 kid 加入
Write-Host "`n8. Testing ownership - Parent trying to join for other kid..." -ForegroundColor Yellow
# 创建第二个 kid（属于另一个 parent）
# 然后尝试用第一个 parent 的 token 加入

Write-Host "Note: This test requires creating a second parent and kid" -ForegroundColor Yellow

Write-Host "`n✅ All tests completed!" -ForegroundColor Green
```

## 测试场景清单

- [ ] Teacher 可以创建班级
- [ ] 班级创建时自动生成唯一的 classCode
- [ ] Teacher 可以查看自己的所有班级
- [ ] Teacher 可以查看自己班级的详情
- [ ] Teacher 不能查看其他 Teacher 的班级（403）
- [ ] Parent 可以为自己的 kid 加入班级
- [ ] Parent 不能为其他 Parent 的 kid 加入班级（403）
- [ ] 重复加入班级被拒绝（409）
- [ ] 无效的 classCode 返回 404
- [ ] 班级详情包含成员列表

## 错误场景测试

### 1. 非 TEACHER 用户创建班级
```bash
curl -X POST http://localhost:3000/api/teacher/classes \
  -H "Authorization: Bearer PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test"}'
```
**预期:** 403 Forbidden

### 2. 非 PARENT 用户加入班级
```bash
curl -X POST http://localhost:3000/api/classes/join \
  -H "Authorization: Bearer TEACHER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"classCode": "ABC123", "kidId": "..."}'
```
**预期:** 403 Forbidden

### 3. 无效的 kidId
```bash
curl -X POST http://localhost:3000/api/classes/join \
  -H "Authorization: Bearer PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"classCode": "ABC123", "kidId": "invalid-id"}'
```
**预期:** 404 Not Found - "Kid not found"

## 注意事项

1. **classCode 生成**: 自动生成 6 位字母数字代码
2. **唯一性**: classCode 在数据库中唯一
3. **所有权检查**: 所有操作都严格验证所有权
4. **成员关系**: 每个 kid 在每个 class 中只有一个成员记录
5. **重复加入**: 如果 kid 已加入，返回 409 Conflict
