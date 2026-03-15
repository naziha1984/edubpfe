# QuizModule 测试指南

## 功能概述

### Kid 端点（需要 kidToken）
- **POST /api/quiz/sessions**: 创建测验会话
- **POST /api/quiz/submit**: 提交答案并计算分数

### Progress 端点
- **GET /api/progress/kids/:kidId**: Kid 查看自己的进度（kidToken）
- **GET /api/progress/parent/kids/:kidId**: Parent 查看 kid 的进度（parentToken）

## 前置要求

1. 安装依赖: `npm install`
2. 运行 seed script: `npm run seed`
3. 启动服务器: `npm run start:dev`
4. 创建科目、课程和测验题目（需要 Admin）

## 测试流程

### 步骤 1: 准备数据

#### 1.1 登录 ADMIN 并创建科目和课程

```bash
# 登录 ADMIN
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@edubridge.com",
    "password": "admin123"
  }'

# 保存 ADMIN_TOKEN

# 创建科目
curl -X POST http://localhost:3000/api/subjects \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Mathematics",
    "code": "MATH"
  }'

# 保存 SUBJECT_ID

# 创建课程
curl -X POST http://localhost:3000/api/lessons \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subjectId": "SUBJECT_ID",
    "title": "Introduction to Algebra",
    "description": "Basic algebra concepts"
  }'

# 保存 LESSON_ID
```

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
    "lastName": "Smith",
    "dateOfBirth": "2015-05-15"
  }'

# 保存 KID_ID
```

#### 1.3 设置 Kid PIN 并获取 kidToken

```bash
# 设置 PIN
curl -X PUT http://localhost:3000/api/kids/$KID_ID/pin \
  -H "Authorization: Bearer $PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"pin": "1234"}'

# 验证 PIN 获取 kidToken
curl -X POST http://localhost:3000/api/kids/$KID_ID/verify-pin \
  -H "Content-Type: application/json" \
  -d '{"pin": "1234"}'

# 保存 KID_TOKEN
```

### 步骤 2: 创建测验会话

```bash
curl -X POST http://localhost:3000/api/quiz/sessions \
  -H "Authorization: Bearer $KID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "kidId": "KID_ID",
    "lessonId": "LESSON_ID"
  }'
```

**预期响应:**
```json
{
  "id": "...",
  "kidId": "...",
  "lessonId": "...",
  "status": "in_progress",
  "createdAt": "..."
}
```

**保存 SESSION_ID**

### 步骤 3: 提交答案

```bash
curl -X POST http://localhost:3000/api/quiz/submit \
  -H "Authorization: Bearer $KID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "SESSION_ID",
    "answers": [
      {"questionIndex": 0, "selectedAnswer": 1},
      {"questionIndex": 1, "selectedAnswer": 0}
    ]
  }'
```

**预期响应:**
```json
{
  "sessionId": "...",
  "score": 2,
  "totalQuestions": 2,
  "percentage": 100,
  "passed": true
}
```

### 步骤 4: 查看进度

#### Kid 查看自己的进度

```bash
curl -X GET http://localhost:3000/api/progress/kids/$KID_ID \
  -H "Authorization: Bearer $KID_TOKEN"
```

**预期响应:**
```json
[
  {
    "id": "...",
    "kidId": "...",
    "lessonId": "...",
    "subjectId": "...",
    "lesson": {...},
    "subject": {...},
    "bestScore": 2,
    "attempts": 1,
    "isCompleted": true,
    "lastAttemptAt": "...",
    "createdAt": "...",
    "updatedAt": "..."
  }
]
```

#### Parent 查看 kid 的进度

```bash
curl -X GET http://localhost:3000/api/progress/parent/kids/$KID_ID \
  -H "Authorization: Bearer $PARENT_TOKEN"
```

## IDOR 保护测试

### 测试 1: Kid 尝试创建其他 kid 的会话

```bash
# 使用 kidToken，但 kidId 不匹配
curl -X POST http://localhost:3000/api/quiz/sessions \
  -H "Authorization: Bearer $KID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "kidId": "OTHER_KID_ID",
    "lessonId": "LESSON_ID"
  }'
```

**预期响应 (403 Forbidden):**
```json
{
  "statusCode": 403,
  "message": "You can only create sessions for yourself"
}
```

### 测试 2: Kid 尝试提交其他 kid 的会话

```bash
# 创建另一个 kid 的会话（使用 ADMIN 或直接创建）
# 然后尝试用第一个 kid 的 token 提交

curl -X POST http://localhost:3000/api/quiz/submit \
  -H "Authorization: Bearer $KID1_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "KID2_SESSION_ID",
    "answers": [{"questionIndex": 0, "selectedAnswer": 1}]
  }'
```

**预期响应 (403 Forbidden):**
```json
{
  "statusCode": 403,
  "message": "You can only submit quizzes for your own sessions"
}
```

### 测试 3: Kid 尝试查看其他 kid 的进度

```bash
curl -X GET http://localhost:3000/api/progress/kids/OTHER_KID_ID \
  -H "Authorization: Bearer $KID_TOKEN"
```

**预期响应 (403 Forbidden):**
```json
{
  "statusCode": 403,
  "message": "You can only view your own progress"
}
```

### 测试 4: Parent 尝试查看其他 parent 的 kid 进度

```bash
# 使用 Parent 1 的 token 查看 Parent 2 的 kid 进度
curl -X GET http://localhost:3000/api/progress/parent/kids/PARENT2_KID_ID \
  -H "Authorization: Bearer $PARENT1_TOKEN"
```

**预期响应 (403 Forbidden):**
```json
{
  "statusCode": 403,
  "message": "You can only view progress for your own kids"
}
```

## 完整测试脚本 (PowerShell)

```powershell
$BASE_URL = "http://localhost:3000/api"

# 1. 登录 ADMIN
Write-Host "1. Logging in as ADMIN..." -ForegroundColor Yellow
$adminLogin = @{
    email = "admin@edubridge.com"
    password = "admin123"
} | ConvertTo-Json

$adminResponse = Invoke-RestMethod -Uri "$BASE_URL/auth/login" `
    -Method Post `
    -ContentType "application/json" `
    -Body $adminLogin

$ADMIN_TOKEN = $adminResponse.access_token
Write-Host "Admin Token received" -ForegroundColor Green

# 2. 创建科目和课程
Write-Host "`n2. Creating subject and lesson..." -ForegroundColor Yellow
$adminHeaders = @{
    Authorization = "Bearer $ADMIN_TOKEN"
}

$subjectBody = @{
    name = "Mathematics"
    code = "MATH"
} | ConvertTo-Json

$subjectResponse = Invoke-RestMethod -Uri "$BASE_URL/subjects" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $adminHeaders `
    -Body $subjectBody

$SUBJECT_ID = $subjectResponse.id

$lessonBody = @{
    subjectId = $SUBJECT_ID
    title = "Introduction to Algebra"
    description = "Basic algebra"
} | ConvertTo-Json

$lessonResponse = Invoke-RestMethod -Uri "$BASE_URL/lessons" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $adminHeaders `
    -Body $lessonBody

$LESSON_ID = $lessonResponse.id
Write-Host "Subject ID: $SUBJECT_ID, Lesson ID: $LESSON_ID" -ForegroundColor Green

# 3. 注册 Parent 并创建 Kid
Write-Host "`n3. Registering parent and creating kid..." -ForegroundColor Yellow
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
    dateOfBirth = "2015-05-15"
} | ConvertTo-Json

$kidResponse = Invoke-RestMethod -Uri "$BASE_URL/kids" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $parentHeaders `
    -Body $kidBody

$KID_ID = $kidResponse.id
Write-Host "Kid ID: $KID_ID" -ForegroundColor Green

# 4. 设置 PIN 并获取 kidToken
Write-Host "`n4. Setting PIN and getting kidToken..." -ForegroundColor Yellow
$pinBody = @{ pin = "1234" } | ConvertTo-Json

Invoke-RestMethod -Uri "$BASE_URL/kids/$KID_ID/pin" `
    -Method Put `
    -ContentType "application/json" `
    -Headers $parentHeaders `
    -Body $pinBody | Out-Null

$verifyPinBody = @{ pin = "1234" } | ConvertTo-Json
$verifyResponse = Invoke-RestMethod -Uri "$BASE_URL/kids/$KID_ID/verify-pin" `
    -Method Post `
    -ContentType "application/json" `
    -Body $verifyPinBody

$KID_TOKEN = $verifyResponse.kidToken
Write-Host "Kid Token received" -ForegroundColor Green

# 5. 创建测验会话
Write-Host "`n5. Creating quiz session..." -ForegroundColor Yellow
$kidHeaders = @{
    Authorization = "Bearer $KID_TOKEN"
}

$sessionBody = @{
    kidId = $KID_ID
    lessonId = $LESSON_ID
} | ConvertTo-Json

$sessionResponse = Invoke-RestMethod -Uri "$BASE_URL/quiz/sessions" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $kidHeaders `
    -Body $sessionBody

$SESSION_ID = $sessionResponse.id
Write-Host "Session ID: $SESSION_ID" -ForegroundColor Green
$sessionResponse | ConvertTo-Json

# 6. 提交答案（注意：需要先创建测验题目）
Write-Host "`n6. Submitting quiz..." -ForegroundColor Yellow
$submitBody = @{
    sessionId = $SESSION_ID
    answers = @(
        @{ questionIndex = 0; selectedAnswer = 1 },
        @{ questionIndex = 1; selectedAnswer = 0 }
    )
} | ConvertTo-Json

try {
    $submitResponse = Invoke-RestMethod -Uri "$BASE_URL/quiz/submit" `
        -Method Post `
        -ContentType "application/json" `
        -Headers $kidHeaders `
        -Body $submitBody
    
    Write-Host "Quiz submitted successfully" -ForegroundColor Green
    $submitResponse | ConvertTo-Json
} catch {
    Write-Host "Note: Quiz submission requires quiz questions to be created first" -ForegroundColor Yellow
    Write-Host $_.Exception.Message
}

# 7. 查看进度
Write-Host "`n7. Viewing progress..." -ForegroundColor Yellow
$progress = Invoke-RestMethod -Uri "$BASE_URL/progress/kids/$KID_ID" `
    -Method Get `
    -Headers $kidHeaders

Write-Host "Progress records: $($progress.Count)" -ForegroundColor Green
$progress | ConvertTo-Json

Write-Host "`n✅ All tests completed!" -ForegroundColor Green
```

## 测试场景清单

- [ ] Kid 可以创建自己的会话
- [ ] Kid 不能创建其他 kid 的会话（403）
- [ ] Kid 可以提交自己的会话答案
- [ ] Kid 不能提交其他 kid 的会话（403）
- [ ] 分数计算正确
- [ ] 进度正确更新（bestScore, attempts, isCompleted）
- [ ] Kid 可以查看自己的进度
- [ ] Kid 不能查看其他 kid 的进度（403）
- [ ] Parent 可以查看自己 kid 的进度
- [ ] Parent 不能查看其他 parent 的 kid 进度（403）
- [ ] 会话完成后不能再次提交（400）

## 注意事项

1. **IDOR 保护**: 所有端点都严格验证所有权
2. **kidToken 验证**: kidId 必须与 token 中的 kidId 匹配
3. **进度更新**: 分数 >= 80% 时标记为完成
4. **最佳分数**: 自动更新为最高分数
5. **尝试次数**: 每次提交增加计数
