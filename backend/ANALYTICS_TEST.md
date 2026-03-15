# Analytics 测试指南

## 功能概述

### Teacher Analytics 端点
- **GET /api/teacher/classes/:classId/subjects/:subjectId/progress**: 获取班级中某个科目的进度统计

**返回数据:**
- 每个 kid 的统计信息（avgScore, lastActivity, completionRate）
- 整体统计信息（totalKids, averageScore, overallCompletionRate）

## 前置要求

1. 安装依赖: `npm install`
2. 运行 seed script: `npm run seed`
3. 启动服务器: `npm run start:dev`
4. 创建班级、添加成员、创建 Progress 数据

## API 端点

### GET /api/teacher/classes/:classId/subjects/:subjectId/progress

获取班级中某个科目的进度统计（需要 TEACHER 角色）

**请求:**
```bash
curl -X GET http://localhost:3000/api/teacher/classes/CLASS_ID/subjects/SUBJECT_ID/progress \
  -H "Authorization: Bearer TEACHER_TOKEN"
```

**预期响应:**
```json
{
  "classId": "...",
  "subjectId": "...",
  "kids": [
    {
      "kidId": "...",
      "kidName": "Alice Smith",
      "avgScore": 85.5,
      "lastActivity": "2026-02-10T15:30:00.000Z",
      "completionRate": 75.0,
      "totalLessons": 4,
      "completedLessons": 3
    },
    {
      "kidId": "...",
      "kidName": "Bob Johnson",
      "avgScore": 92.0,
      "lastActivity": "2026-02-10T16:45:00.000Z",
      "completionRate": 100.0,
      "totalLessons": 4,
      "completedLessons": 4
    }
  ],
  "overallStats": {
    "totalKids": 2,
    "averageScore": 88.75,
    "overallCompletionRate": 87.5
  }
}
```

## 完整测试流程

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

#### 1.2 创建班级

```bash
curl -X POST http://localhost:3000/api/teacher/classes \
  -H "Authorization: Bearer $TEACHER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Math Class 2024",
    "description": "Advanced Mathematics"
  }'
```

**保存 CLASS_ID**

#### 1.3 创建科目和课程

```bash
# 登录 ADMIN
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@edubridge.com", "password": "admin123"}'

# 保存 ADMIN_TOKEN

# 创建科目
curl -X POST http://localhost:3000/api/subjects \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Mathematics", "code": "MATH"}'

# 保存 SUBJECT_ID

# 创建课程
curl -X POST http://localhost:3000/api/lessons \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subjectId": "SUBJECT_ID",
    "title": "Algebra Basics",
    "order": 1
  }'

# 保存 LESSON_ID_1

curl -X POST http://localhost:3000/api/lessons \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subjectId": "SUBJECT_ID",
    "title": "Geometry",
    "order": 2
  }'

# 保存 LESSON_ID_2
```

#### 1.4 注册 Parent 并创建 Kids

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

# 创建 Kid 1
curl -X POST http://localhost:3000/api/kids \
  -H "Authorization: Bearer $PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"firstName": "Alice", "lastName": "Smith"}'

# 保存 KID1_ID

# 创建 Kid 2
curl -X POST http://localhost:3000/api/kids \
  -H "Authorization: Bearer $PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"firstName": "Bob", "lastName": "Johnson"}'

# 保存 KID2_ID
```

#### 1.5 加入班级

```bash
# 获取 classCode
curl -X GET http://localhost:3000/api/teacher/classes/$CLASS_ID \
  -H "Authorization: Bearer $TEACHER_TOKEN"

# 保存 CLASS_CODE

# Kid 1 加入班级
curl -X POST http://localhost:3000/api/classes/join \
  -H "Authorization: Bearer $PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "classCode": "CLASS_CODE",
    "kidId": "KID1_ID"
  }'

# Kid 2 加入班级
curl -X POST http://localhost:3000/api/classes/join \
  -H "Authorization: Bearer $PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "classCode": "CLASS_CODE",
    "kidId": "KID2_ID"
  }'
```

#### 1.6 创建 Progress 数据（通过 Quiz）

```bash
# 设置 PIN 并获取 kidToken
curl -X PUT http://localhost:3000/api/kids/KID1_ID/pin \
  -H "Authorization: Bearer $PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"pin": "1234"}'

curl -X POST http://localhost:3000/api/kids/KID1_ID/verify-pin \
  -H "Content-Type: application/json" \
  -d '{"pin": "1234"}'

# 保存 KID1_TOKEN

# 创建 Quiz Session 并提交（这会创建 Progress）
curl -X POST http://localhost:3000/api/quiz/sessions \
  -H "Authorization: Bearer $KID1_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "kidId": "KID1_ID",
    "lessonId": "LESSON_ID_1"
  }'

# 保存 SESSION_ID

# 提交答案（需要先创建 QuizQuestion，这里假设已创建）
curl -X POST http://localhost:3000/api/quiz/submit \
  -H "Authorization: Bearer $KID1_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "SESSION_ID",
    "answers": [
      {"questionIndex": 0, "selectedAnswer": 1}
    ]
  }'
```

### 步骤 2: 获取 Analytics

```bash
curl -X GET http://localhost:3000/api/teacher/classes/$CLASS_ID/subjects/$SUBJECT_ID/progress \
  -H "Authorization: Bearer $TEACHER_TOKEN"
```

## JSON 响应示例

### 示例 1: 有数据的响应

```json
{
  "classId": "507f1f77bcf86cd799439011",
  "subjectId": "507f191e810c19729de860ea",
  "kids": [
    {
      "kidId": "507f1f77bcf86cd799439012",
      "kidName": "Alice Smith",
      "avgScore": 85.5,
      "lastActivity": "2026-02-10T15:30:00.000Z",
      "completionRate": 75.0,
      "totalLessons": 4,
      "completedLessons": 3
    },
    {
      "kidId": "507f1f77bcf86cd799439013",
      "kidName": "Bob Johnson",
      "avgScore": 92.0,
      "lastActivity": "2026-02-10T16:45:00.000Z",
      "completionRate": 100.0,
      "totalLessons": 4,
      "completedLessons": 4
    },
    {
      "kidId": "507f1f77bcf86cd799439014",
      "kidName": "Charlie Brown",
      "avgScore": 0,
      "lastActivity": null,
      "completionRate": 0,
      "totalLessons": 0,
      "completedLessons": 0
    }
  ],
  "overallStats": {
    "totalKids": 3,
    "averageScore": 88.75,
    "overallCompletionRate": 58.33
  }
}
```

### 示例 2: 空班级

```json
{
  "classId": "507f1f77bcf86cd799439011",
  "subjectId": "507f191e810c19729de860ea",
  "kids": [],
  "overallStats": {
    "totalKids": 0,
    "averageScore": 0,
    "overallCompletionRate": 0
  }
}
```

### 示例 3: 有成员但无进度数据

```json
{
  "classId": "507f1f77bcf86cd799439011",
  "subjectId": "507f191e810c19729de860ea",
  "kids": [
    {
      "kidId": "507f1f77bcf86cd799439012",
      "kidName": "Alice Smith",
      "avgScore": 0,
      "lastActivity": null,
      "completionRate": 0,
      "totalLessons": 0,
      "completedLessons": 0
    }
  ],
  "overallStats": {
    "totalKids": 1,
    "averageScore": 0,
    "overallCompletionRate": 0
  }
}
```

## MongoDB Aggregation 说明

### Aggregation Pipeline

```javascript
[
  // Stage 1: Match progress records
  {
    $match: {
      kidId: { $in: [kidIds] },
      subjectId: ObjectId(subjectId)
    }
  },
  // Stage 2: Group by kidId
  {
    $group: {
      _id: '$kidId',
      avgScore: { $avg: '$bestScore' },
      maxLastActivity: { $max: '$lastAttemptAt' },
      completedCount: { $sum: { $cond: ['$isCompleted', 1, 0] } },
      totalLessons: { $sum: 1 }
    }
  },
  // Stage 3: Lookup kid information
  {
    $lookup: {
      from: 'kids',
      localField: '_id',
      foreignField: '_id',
      as: 'kid'
    }
  },
  // Stage 4: Unwind kid array
  {
    $unwind: {
      path: '$kid',
      preserveNullAndEmptyArrays: true
    }
  },
  // Stage 5: Project final structure
  {
    $project: {
      kidId: { $toString: '$_id' },
      kidName: { $concat: ['$kid.firstName', ' ', '$kid.lastName'] },
      avgScore: { $round: ['$avgScore', 2] },
      lastActivity: '$maxLastActivity',
      completedLessons: '$completedCount',
      totalLessons: '$totalLessons',
      completionRate: {
        $cond: [
          { $gt: ['$totalLessons', 0] },
          { $round: [{ $multiply: [{ $divide: ['$completedCount', '$totalLessons'] }, 100] }, 2] },
          0
        ]
      }
    }
  }
]
```

## 计算说明

### avgScore
- 计算方式: `$avg: '$bestScore'`
- 含义: 该 kid 在该 subject 所有 lessons 的最佳分数平均值

### lastActivity
- 计算方式: `$max: '$lastAttemptAt'`
- 含义: 该 kid 在该 subject 最后一次尝试的时间

### completionRate
- 计算方式: `(completedLessons / totalLessons) * 100`
- 含义: 完成率百分比（已完成 lessons / 总 lessons）

### overallStats
- `averageScore`: 所有有进度的 kids 的平均分数平均值
- `overallCompletionRate`: 所有有进度的 kids 的完成率平均值

## 所有权检查测试

### 测试 1: Teacher 尝试查看其他 Teacher 的班级

```bash
curl -X GET http://localhost:3000/api/teacher/classes/OTHER_TEACHER_CLASS_ID/subjects/SUBJECT_ID/progress \
  -H "Authorization: Bearer TEACHER_TOKEN"
```

**预期响应 (403 Forbidden):**
```json
{
  "statusCode": 403,
  "message": "You can only view analytics for your own classes"
}
```

### 测试 2: 非 TEACHER 用户访问

```bash
curl -X GET http://localhost:3000/api/teacher/classes/CLASS_ID/subjects/SUBJECT_ID/progress \
  -H "Authorization: Bearer PARENT_TOKEN"
```

**预期响应 (403 Forbidden):**
```json
{
  "statusCode": 403,
  "message": "Forbidden resource"
}
```

## Windows PowerShell 测试脚本

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

# 2. 获取 Analytics
Write-Host "`n2. Getting analytics..." -ForegroundColor Yellow
$teacherHeaders = @{
    Authorization = "Bearer $TEACHER_TOKEN"
}

# 假设已有 CLASS_ID 和 SUBJECT_ID
$analytics = Invoke-RestMethod -Uri "$BASE_URL/teacher/classes/CLASS_ID/subjects/SUBJECT_ID/progress" `
    -Method Get `
    -Headers $teacherHeaders

Write-Host "Analytics retrieved successfully" -ForegroundColor Green
$analytics | ConvertTo-Json -Depth 10

Write-Host "`n✅ Test completed!" -ForegroundColor Green
```

## 测试场景清单

- [ ] Teacher 可以查看自己班级的 analytics
- [ ] Teacher 不能查看其他 Teacher 的班级 analytics（403）
- [ ] 非 TEACHER 用户不能访问（403）
- [ ] 空班级返回空数组
- [ ] 有成员但无进度数据时返回 0 值
- [ ] avgScore 计算正确
- [ ] lastActivity 显示最新活动时间
- [ ] completionRate 计算正确
- [ ] overallStats 计算正确

## 注意事项

1. **所有权检查**: 严格验证 teacher 拥有该班级
2. **数据聚合**: 使用 MongoDB aggregation 高效计算统计
3. **空值处理**: 无进度数据的 kid 显示 0 值
4. **完成率计算**: 基于 isCompleted 字段计算
5. **平均分数**: 基于 bestScore 字段计算
