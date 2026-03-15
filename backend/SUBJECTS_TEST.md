# Subjects/Lessons 测试指南

## 功能概述

### 公开端点（无需认证）
- **GET /api/subjects**: 获取所有活跃科目
- **GET /api/subjects/:id/lessons**: 获取某个科目的所有课程

### Admin 端点（需要 ADMIN 角色）
- **POST /api/subjects**: 创建科目
- **GET /api/subjects/admin/:id**: 获取科目详情（包括非活跃）
- **PUT /api/subjects/:id**: 更新科目
- **DELETE /api/subjects/:id**: 删除科目
- **POST /api/lessons**: 创建课程
- **GET /api/lessons/:id**: 获取课程详情
- **PUT /api/lessons/:id**: 更新课程
- **DELETE /api/lessons/:id**: 删除课程

## 前置要求

1. 安装依赖: `npm install`
2. 运行 seed script: `npm run seed` (创建 ADMIN 用户)
3. 启动服务器: `npm run start:dev`

## 公开端点测试

### 1. GET /api/subjects

获取所有活跃科目（无需认证）

**请求:**
```bash
curl -X GET http://localhost:3000/api/subjects
```

**预期响应:**
```json
[
  {
    "id": "...",
    "name": "Mathematics",
    "description": "Math subject",
    "code": "MATH",
    "isActive": true,
    "createdAt": "...",
    "updatedAt": "..."
  }
]
```

### 2. GET /api/subjects/:id/lessons

获取某个科目的所有课程（无需认证）

**请求:**
```bash
curl -X GET http://localhost:3000/api/subjects/SUBJECT_ID/lessons
```

**预期响应:**
```json
[
  {
    "id": "...",
    "subjectId": "...",
    "title": "Introduction to Algebra",
    "description": "Basic algebra concepts",
    "content": "...",
    "order": 1,
    "isActive": true,
    "createdAt": "...",
    "updatedAt": "..."
  }
]
```

## Admin 端点测试

### 步骤 1: 登录 ADMIN

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@edubridge.com",
    "password": "admin123"
  }'
```

保存 `ADMIN_TOKEN`

### 步骤 2: 创建科目

```bash
curl -X POST http://localhost:3000/api/subjects \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Mathematics",
    "description": "Mathematics subject",
    "code": "MATH",
    "isActive": true
  }'
```

**预期响应:**
```json
{
  "id": "...",
  "name": "Mathematics",
  "description": "Mathematics subject",
  "code": "MATH",
  "isActive": true,
  "createdAt": "...",
  "updatedAt": "..."
}
```

保存 `SUBJECT_ID`

### 步骤 3: 获取科目详情

```bash
curl -X GET http://localhost:3000/api/subjects/admin/$SUBJECT_ID \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### 步骤 4: 更新科目

```bash
curl -X PUT http://localhost:3000/api/subjects/$SUBJECT_ID \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Updated description",
    "code": "MATH101"
  }'
```

### 步骤 5: 创建课程

```bash
curl -X POST http://localhost:3000/api/lessons \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subjectId": "SUBJECT_ID",
    "title": "Introduction to Algebra",
    "description": "Basic algebra concepts",
    "content": "Lesson content here...",
    "order": 1,
    "isActive": true
  }'
```

**预期响应:**
```json
{
  "id": "...",
  "subjectId": "...",
  "title": "Introduction to Algebra",
  "description": "Basic algebra concepts",
  "content": "Lesson content here...",
  "order": 1,
  "isActive": true,
  "createdAt": "...",
  "updatedAt": "..."
}
```

保存 `LESSON_ID`

### 步骤 6: 获取课程详情

```bash
curl -X GET http://localhost:3000/api/lessons/$LESSON_ID \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### 步骤 7: 更新课程

```bash
curl -X PUT http://localhost:3000/api/lessons/$LESSON_ID \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Advanced Algebra",
    "order": 2
  }'
```

### 步骤 8: 删除课程

```bash
curl -X DELETE http://localhost:3000/api/lessons/$LESSON_ID \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

**预期响应:** 204 No Content

### 步骤 9: 删除科目

```bash
curl -X DELETE http://localhost:3000/api/subjects/$SUBJECT_ID \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

**预期响应:** 204 No Content

## 唯一索引测试

### 测试 1: 重复科目名称

```bash
# 创建第一个科目
curl -X POST http://localhost:3000/api/subjects \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Science"}'

# 尝试创建同名科目（应该失败）
curl -X POST http://localhost:3000/api/subjects \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Science"}'
```

**预期响应 (409 Conflict):**
```json
{
  "statusCode": 409,
  "message": "Subject with this name already exists",
  "timestamp": "...",
  "path": "/api/subjects",
  "method": "POST"
}
```

### 测试 2: 同一科目内重复课程标题

```bash
# 创建第一个课程
curl -X POST http://localhost:3000/api/lessons \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subjectId": "SUBJECT_ID",
    "title": "Lesson 1"
  }'

# 尝试在同一科目创建同名课程（应该失败）
curl -X POST http://localhost:3000/api/lessons \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subjectId": "SUBJECT_ID",
    "title": "Lesson 1"
  }'
```

**预期响应 (409 Conflict):**
```json
{
  "statusCode": 409,
  "message": "Lesson with this title already exists in this subject",
  "timestamp": "...",
  "path": "/api/lessons",
  "method": "POST"
}
```

### 测试 3: 不同科目可以有相同课程标题

```bash
# 创建科目 1
curl -X POST http://localhost:3000/api/subjects \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Math"}'

# 创建科目 2
curl -X POST http://localhost:3000/api/subjects \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Science"}'

# 在科目 1 创建课程
curl -X POST http://localhost:3000/api/lessons \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subjectId": "SUBJECT1_ID",
    "title": "Introduction"
  }'

# 在科目 2 创建同名课程（应该成功）
curl -X POST http://localhost:3000/api/lessons \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subjectId": "SUBJECT2_ID",
    "title": "Introduction"
  }'
```

**验证:** 应该成功创建，因为不同科目可以有相同标题

## 权限测试

### 测试 1: 非 ADMIN 用户尝试创建科目

```bash
# 使用 PARENT token
curl -X POST http://localhost:3000/api/subjects \
  -H "Authorization: Bearer PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test"}'
```

**预期响应 (403 Forbidden):**
```json
{
  "statusCode": 403,
  "message": "Forbidden resource",
  "timestamp": "...",
  "path": "/api/subjects",
  "method": "POST"
}
```

### 测试 2: 未认证用户访问公开端点

```bash
# 应该成功（公开端点）
curl -X GET http://localhost:3000/api/subjects

# 应该成功（公开端点）
curl -X GET http://localhost:3000/api/subjects/SUBJECT_ID/lessons
```

**验证:** 应该返回数据，无需认证

## Windows PowerShell 测试脚本

```powershell
$BASE_URL = "http://localhost:3000/api"

# 1. 登录 ADMIN
Write-Host "1. Logging in as ADMIN..." -ForegroundColor Yellow
$loginBody = @{
    email = "admin@edubridge.com"
    password = "admin123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "$BASE_URL/auth/login" `
    -Method Post `
    -ContentType "application/json" `
    -Body $loginBody

$ADMIN_TOKEN = $loginResponse.access_token
Write-Host "Admin Token: $($ADMIN_TOKEN.Substring(0, 50))..." -ForegroundColor Gray

# 2. 测试公开端点 - 获取所有科目
Write-Host "`n2. Testing public endpoint - Get all subjects..." -ForegroundColor Yellow
$subjects = Invoke-RestMethod -Uri "$BASE_URL/subjects" -Method Get
Write-Host "Found $($subjects.Count) subject(s)" -ForegroundColor Green
$subjects | ConvertTo-Json

# 3. 创建科目
Write-Host "`n3. Creating subject..." -ForegroundColor Yellow
$subjectBody = @{
    name = "Mathematics"
    description = "Mathematics subject"
    code = "MATH"
    isActive = $true
} | ConvertTo-Json

$adminHeaders = @{
    Authorization = "Bearer $ADMIN_TOKEN"
}

$subjectResponse = Invoke-RestMethod -Uri "$BASE_URL/subjects" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $adminHeaders `
    -Body $subjectBody

$SUBJECT_ID = $subjectResponse.id
Write-Host "Subject ID: $SUBJECT_ID" -ForegroundColor Green
$subjectResponse | ConvertTo-Json

# 4. 创建课程
Write-Host "`n4. Creating lesson..." -ForegroundColor Yellow
$lessonBody = @{
    subjectId = $SUBJECT_ID
    title = "Introduction to Algebra"
    description = "Basic algebra concepts"
    content = "Lesson content here..."
    order = 1
    isActive = $true
} | ConvertTo-Json

$lessonResponse = Invoke-RestMethod -Uri "$BASE_URL/lessons" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $adminHeaders `
    -Body $lessonBody

$LESSON_ID = $lessonResponse.id
Write-Host "Lesson ID: $LESSON_ID" -ForegroundColor Green
$lessonResponse | ConvertTo-Json

# 5. 测试公开端点 - 获取科目的课程
Write-Host "`n5. Testing public endpoint - Get lessons by subject..." -ForegroundColor Yellow
$lessons = Invoke-RestMethod -Uri "$BASE_URL/subjects/$SUBJECT_ID/lessons" -Method Get
Write-Host "Found $($lessons.Count) lesson(s)" -ForegroundColor Green
$lessons | ConvertTo-Json

# 6. 测试唯一索引 - 重复科目名称
Write-Host "`n6. Testing unique index - Duplicate subject name..." -ForegroundColor Yellow
try {
    $duplicateSubject = Invoke-RestMethod -Uri "$BASE_URL/subjects" `
        -Method Post `
        -ContentType "application/json" `
        -Headers $adminHeaders `
        -Body $subjectBody
    
    Write-Host "❌ Should have failed" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "✅ Correctly rejected duplicate subject name (409)" -ForegroundColor Green
    } else {
        Write-Host "❌ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 7. 测试唯一索引 - 重复课程标题（同一科目）
Write-Host "`n7. Testing unique index - Duplicate lesson title in same subject..." -ForegroundColor Yellow
try {
    $duplicateLesson = Invoke-RestMethod -Uri "$BASE_URL/lessons" `
        -Method Post `
        -ContentType "application/json" `
        -Headers $adminHeaders `
        -Body $lessonBody
    
    Write-Host "❌ Should have failed" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "✅ Correctly rejected duplicate lesson title (409)" -ForegroundColor Green
    } else {
        Write-Host "❌ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n✅ All tests completed!" -ForegroundColor Green
```

## 测试场景清单

- [ ] 公开端点无需认证即可访问
- [ ] 可以获取所有活跃科目
- [ ] 可以获取某个科目的所有课程
- [ ] ADMIN 可以创建科目
- [ ] ADMIN 可以更新科目
- [ ] ADMIN 可以删除科目
- [ ] ADMIN 可以创建课程
- [ ] ADMIN 可以更新课程
- [ ] ADMIN 可以删除课程
- [ ] 重复科目名称被拒绝（409）
- [ ] 同一科目内重复课程标题被拒绝（409）
- [ ] 不同科目可以有相同课程标题
- [ ] 非 ADMIN 用户无法创建/更新/删除
- [ ] DTO 验证工作正常

## 错误场景测试

### 1. 无效科目 ID
```bash
curl -X GET http://localhost:3000/api/subjects/invalid-id/lessons
```
**预期:** 404 Not Found

### 2. 无效课程 ID
```bash
curl -X GET http://localhost:3000/api/lessons/invalid-id \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```
**预期:** 404 Not Found

### 3. 无效 subjectId 创建课程
```bash
curl -X POST http://localhost:3000/api/lessons \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subjectId": "invalid-id",
    "title": "Test"
  }'
```
**预期:** 404 Not Found - "Subject not found"

### 4. 无效 DTO 数据
```bash
curl -X POST http://localhost:3000/api/subjects \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```
**预期:** 400 Bad Request - 验证错误
