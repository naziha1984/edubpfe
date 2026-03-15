# Gamification (Rewards) 测试指南

## 功能概述

### Gamification 功能
- **XP 系统**: Quiz 提交后自动获得 XP
- **Badges**: 基于成就的徽章系统
- **Streak**: 每日连续签到系统

### API 端点
- **GET /api/kids/:kidId/rewards**: Parent 查看 kid 的奖励（需要 parentToken）
- **GET /api/kid/rewards**: Kid 查看自己的奖励（需要 kidToken）
- **POST /api/kid/streak**: Kid 更新每日 streak（需要 kidToken）

## 前置要求

1. 安装依赖: `npm install`
2. 运行 seed script: `npm run seed`
3. 运行 badge seed: `npm run seed:badges`
4. 启动服务器: `npm run start:dev`

## Badge 类型

### 已定义的 Badges
- **QUIZ_MASTER**: 完成 10 个测验
- **PERFECT_SCORE**: 获得 100% 分数
- **STREAK_7**: 7 天连续签到
- **STREAK_30**: 30 天连续签到
- **XP_1000**: 达到 1000 XP
- **XP_5000**: 达到 5000 XP

## XP 系统

### Quiz XP 计算
- **基础 XP**: 50 XP（完成测验）
- **分数奖励**: `(score / totalQuestions) * 50`（最多 50 XP）
- **总 XP**: 基础 XP + 分数奖励（最多 100 XP）

### Streak XP 计算
- **第一天**: 10 XP
- **连续天数**: 10 + (streak * 2) XP
- **示例**: 
  - Day 1: 10 XP
  - Day 2: 14 XP (10 + 2*2)
  - Day 7: 24 XP (10 + 7*2)

### Level 系统
- **每级需要**: 1000 XP
- **Level 计算**: `Math.floor(totalXP / 1000)`

## 测试流程

### 步骤 1: 准备数据

#### 1.1 运行 Badge Seed

```bash
npm run seed:badges
```

这将创建所有 badge 定义。

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
  -d '{"firstName": "Alice", "lastName": "Smith"}'

# 保存 KID_ID
```

#### 1.3 设置 PIN 并获取 kidToken

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

### 步骤 2: 测试 Quiz XP

```bash
# 创建并提交 Quiz（假设已有 lesson 和 questions）
curl -X POST http://localhost:3000/api/quiz/sessions \
  -H "Authorization: Bearer $KID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "kidId": "KID_ID",
    "lessonId": "LESSON_ID"
  }'

# 保存 SESSION_ID

# 提交答案
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

**预期响应包含 xpEarned:**
```json
{
  "sessionId": "...",
  "score": 2,
  "totalQuestions": 2,
  "percentage": 100,
  "passed": true,
  "xpEarned": 100
}
```

### 步骤 3: 测试 Streak

```bash
# Kid 更新每日 streak
curl -X POST http://localhost:3000/api/kid/streak \
  -H "Authorization: Bearer $KID_TOKEN"
```

**预期响应:**
```json
{
  "streak": 1,
  "xpEarned": 10,
  "message": "Streak updated! Current streak: 1 days. Earned 10 XP."
}
```

**第二天再次调用:**
```json
{
  "streak": 2,
  "xpEarned": 14,
  "message": "Streak updated! Current streak: 2 days. Earned 14 XP."
}
```

### 步骤 4: 查看 Rewards

#### Parent 查看

```bash
curl -X GET http://localhost:3000/api/kids/$KID_ID/rewards \
  -H "Authorization: Bearer $PARENT_TOKEN"
```

#### Kid 查看

```bash
curl -X GET http://localhost:3000/api/kid/rewards \
  -H "Authorization: Bearer $KID_TOKEN"
```

**预期响应:**
```json
{
  "kidId": "...",
  "totalXP": 150,
  "currentLevel": 0,
  "xpForNextLevel": 850,
  "currentStreak": 2,
  "lastStreakDate": "2026-02-10T00:00:00.000Z",
  "badges": [
    {
      "id": "...",
      "type": "PERFECT_SCORE",
      "name": "Perfect Score",
      "description": "Get 100% on a quiz",
      "icon": "⭐"
    }
  ],
  "recentHistory": [
    {
      "id": "...",
      "xpEarned": 14,
      "source": "streak",
      "description": "Daily streak: 2 days",
      "createdAt": "2026-02-10T..."
    },
    {
      "id": "...",
      "xpEarned": 100,
      "source": "quiz",
      "description": "Quiz completed: 2/2 (100%)",
      "createdAt": "2026-02-10T..."
    }
  ]
}
```

## Badge 触发测试

### 测试 1: Perfect Score Badge

```bash
# 提交一个 100% 的测验
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

# 查看 rewards，应该包含 PERFECT_SCORE badge
```

### 测试 2: Streak Badges

```bash
# 连续 7 天调用 streak 端点
# 第 7 天应该获得 STREAK_7 badge

# 连续 30 天调用 streak 端点
# 第 30 天应该获得 STREAK_30 badge
```

### 测试 3: XP Badges

```bash
# 通过完成测验累积 XP
# 达到 1000 XP 时获得 XP_1000 badge
# 达到 5000 XP 时获得 XP_5000 badge
```

### 测试 4: Quiz Master Badge

```bash
# 完成 10 个测验
# 第 10 个测验完成后应该获得 QUIZ_MASTER badge
```

## 所有权检查测试

### 测试 1: Parent 尝试查看其他 Parent 的 kid rewards

```bash
curl -X GET http://localhost:3000/api/kids/OTHER_PARENT_KID_ID/rewards \
  -H "Authorization: Bearer PARENT_TOKEN"
```

**预期响应 (403 Forbidden):**
```json
{
  "statusCode": 403,
  "message": "You can only view rewards for your own kids"
}
```

### 测试 2: Kid 尝试查看其他 kid 的 rewards

```bash
curl -X GET http://localhost:3000/api/kid/rewards \
  -H "Authorization: Bearer KID1_TOKEN"
```

**验证:** 只能看到自己的 rewards（kidToken 中的 kidId 自动匹配）

## 完整测试脚本 (PowerShell)

```powershell
$BASE_URL = "http://localhost:3000/api"

# 1. 运行 Badge Seed
Write-Host "1. Seeding badges..." -ForegroundColor Yellow
# 需要在终端运行: npm run seed:badges

# 2. 注册 Parent 并创建 Kid
Write-Host "`n2. Registering parent and creating kid..." -ForegroundColor Yellow
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

# 3. 设置 PIN 并获取 kidToken
Write-Host "`n3. Setting PIN and getting kidToken..." -ForegroundColor Yellow
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

# 4. 更新 Streak
Write-Host "`n4. Updating streak..." -ForegroundColor Yellow
$kidHeaders = @{
    Authorization = "Bearer $KID_TOKEN"
}

$streakResponse = Invoke-RestMethod -Uri "$BASE_URL/kid/streak" `
    -Method Post `
    -Headers $kidHeaders

Write-Host "Streak: $($streakResponse.streak) days" -ForegroundColor Green
Write-Host "XP Earned: $($streakResponse.xpEarned)" -ForegroundColor Green
$streakResponse | ConvertTo-Json

# 5. 查看 Rewards (Kid)
Write-Host "`n5. Viewing rewards (Kid)..." -ForegroundColor Yellow
$kidRewards = Invoke-RestMethod -Uri "$BASE_URL/kid/rewards" `
    -Method Get `
    -Headers $kidHeaders

Write-Host "Total XP: $($kidRewards.totalXP)" -ForegroundColor Green
Write-Host "Level: $($kidRewards.currentLevel)" -ForegroundColor Green
Write-Host "Streak: $($kidRewards.currentStreak) days" -ForegroundColor Green
Write-Host "Badges: $($kidRewards.badges.Count)" -ForegroundColor Green
$kidRewards | ConvertTo-Json -Depth 10

# 6. 查看 Rewards (Parent)
Write-Host "`n6. Viewing rewards (Parent)..." -ForegroundColor Yellow
$parentRewards = Invoke-RestMethod -Uri "$BASE_URL/kids/$KID_ID/rewards" `
    -Method Get `
    -Headers $parentHeaders

$parentRewards | ConvertTo-Json -Depth 10

Write-Host "`n✅ All tests completed!" -ForegroundColor Green
```

## 测试场景清单

- [ ] Badge seed 运行成功
- [ ] Quiz 提交后获得 XP
- [ ] XP 计算正确（基础 + 分数奖励）
- [ ] Streak 第一天获得 10 XP
- [ ] Streak 连续天数获得额外 XP
- [ ] Streak 中断后重置
- [ ] Level 计算正确（每 1000 XP 一级）
- [ ] Perfect Score badge 触发
- [ ] Quiz Master badge 触发（10 个测验）
- [ ] Streak 7 badge 触发
- [ ] Streak 30 badge 触发
- [ ] XP 1000 badge 触发
- [ ] XP 5000 badge 触发
- [ ] Kid 可以查看自己的 rewards
- [ ] Parent 可以查看自己 kid 的 rewards
- [ ] Parent 不能查看其他 kid 的 rewards（403）

## 注意事项

1. **XP 计算**: 基础 50 XP + 分数奖励（最多 50 XP）= 最多 100 XP
2. **Streak 计算**: 第一天 10 XP，之后每天 10 + (streak * 2) XP
3. **Level 系统**: 每 1000 XP 升一级
4. **Badge 自动授予**: 满足条件时自动授予，不会重复授予
5. **Streak 重置**: 如果超过 1 天未签到，streak 重置为 1
