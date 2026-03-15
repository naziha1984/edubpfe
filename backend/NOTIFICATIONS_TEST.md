# Notifications 测试指南

## 功能概述

### 通知系统
- **Notification Model**: 通知数据模型
- **通知规则**:
  - **作业到期前24小时**: 当作业在24小时内到期时，通知 parent 和 teacher
  - **3天不活动**: 当 kid 3天没有活动时，通知 parent

### API 端点
- **GET /api/notifications**: 获取通知列表（需要 PARENT 或 TEACHER 角色）
- **PATCH /api/notifications/:id/read**: 标记通知为已读

## 前置要求

1. 安装依赖: `npm install`（包括 `@nestjs/schedule`）
2. 运行 seed script: `npm run seed`
3. 启动服务器: `npm run start:dev`
4. Cron jobs 会自动运行

## Cron 计划

### 作业到期检查
- **频率**: 每6小时
- **Cron**: `0 */6 * * *` (UTC)
- **功能**: 检查24小时内到期的作业，创建通知

### 不活动检查
- **频率**: 每天凌晨2点
- **Cron**: `0 2 * * *` (UTC)
- **功能**: 检查3天不活动的 kids，创建通知

### 清理旧通知
- **频率**: 每天凌晨3点
- **Cron**: `0 3 * * *` (UTC)
- **功能**: 删除30天前已读的通知

## API 端点

### GET /api/notifications

获取通知列表（需要 PARENT 或 TEACHER 角色）

**请求:**
```bash
curl -X GET http://localhost:3000/api/notifications \
  -H "Authorization: Bearer TOKEN"
```

**查询参数:**
- `status` (可选): `unread` 或 `read` 过滤通知

**示例:**
```bash
# 获取所有通知
curl -X GET http://localhost:3000/api/notifications \
  -H "Authorization: Bearer TOKEN"

# 只获取未读通知
curl -X GET "http://localhost:3000/api/notifications?status=unread" \
  -H "Authorization: Bearer TOKEN"

# 只获取已读通知
curl -X GET "http://localhost:3000/api/notifications?status=read" \
  -H "Authorization: Bearer TOKEN"
```

**预期响应:**
```json
[
  {
    "id": "...",
    "type": "ASSIGNMENT_DUE_24H",
    "status": "UNREAD",
    "title": "Assignment Due Soon",
    "message": "Assignment \"Math Homework\" is due in less than 24 hours for Alice Smith",
    "kidId": "...",
    "relatedId": "...",
    "relatedType": "assignment",
    "readAt": null,
    "createdAt": "2026-02-10T...",
    "updatedAt": "2026-02-10T..."
  },
  {
    "id": "...",
    "type": "INACTIVITY_3_DAYS",
    "status": "UNREAD",
    "title": "Inactivity Alert",
    "message": "Alice Smith has been inactive for 3 days",
    "kidId": "...",
    "relatedId": null,
    "relatedType": "kid",
    "readAt": null,
    "createdAt": "2026-02-10T...",
    "updatedAt": "2026-02-10T..."
  }
]
```

### PATCH /api/notifications/:id/read

标记通知为已读

**请求:**
```bash
curl -X PATCH http://localhost:3000/api/notifications/NOTIFICATION_ID/read \
  -H "Authorization: Bearer TOKEN"
```

**预期响应:**
```json
{
  "id": "...",
  "status": "READ",
  "readAt": "2026-02-10T..."
}
```

## 测试流程

### 步骤 1: 准备数据

#### 1.1 注册 Parent 并创建 Kid

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

#### 1.2 注册 Teacher 并创建班级

```bash
# 登录 Teacher（或使用 seed script 创建的）
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teacher@edubridge.com",
    "password": "teacher123"
  }'

# 保存 TEACHER_TOKEN

# 创建班级
curl -X POST http://localhost:3000/api/teacher/classes \
  -H "Authorization: Bearer $TEACHER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Math Class",
    "description": "Mathematics"
  }'

# 保存 CLASS_ID
```

#### 1.3 创建作业（Assignment）

**注意**: 需要手动在数据库中创建 Assignment，或通过 API 创建（如果实现了 Assignment CRUD）

```javascript
// MongoDB 示例
db.assignments.insertOne({
  classId: ObjectId("CLASS_ID"),
  teacherId: ObjectId("TEACHER_ID"),
  title: "Math Homework",
  description: "Complete exercises 1-10",
  dueDate: new Date(Date.now() + 20 * 60 * 60 * 1000), // 20小时后到期
  isActive: true
})
```

### 步骤 2: 测试通知

#### 2.1 查看通知（Parent）

```bash
curl -X GET http://localhost:3000/api/notifications \
  -H "Authorization: Bearer $PARENT_TOKEN"
```

#### 2.2 查看未读通知

```bash
curl -X GET "http://localhost:3000/api/notifications?status=unread" \
  -H "Authorization: Bearer $PARENT_TOKEN"
```

#### 2.3 标记通知为已读

```bash
curl -X PATCH http://localhost:3000/api/notifications/NOTIFICATION_ID/read \
  -H "Authorization: Bearer $PARENT_TOKEN"
```

### 步骤 3: 测试 Cron Jobs

#### 3.1 手动触发作业到期检查

**注意**: 在实际环境中，cron jobs 会自动运行。测试时可以手动调用服务方法。

```typescript
// 在代码中或通过测试脚本
await notificationsService.checkAssignmentDueNotifications();
```

#### 3.2 手动触发不活动检查

```typescript
await notificationsService.checkInactivityNotifications();
```

## 通知规则测试

### 测试 1: 作业到期前24小时

1. 创建一个作业，dueDate 设置为 20 小时后
2. 等待 cron job 运行（或手动触发）
3. 检查 parent 和 teacher 是否收到通知

**预期结果:**
- Parent 收到通知: "Assignment \"Math Homework\" is due in less than 24 hours for Alice Smith"
- Teacher 收到通知: "Assignment \"Math Homework\" is due in less than 24 hours. Student: Alice Smith"

### 测试 2: 3天不活动

1. 确保 kid 的最后活动（Progress.lastAttemptAt）超过3天
2. 等待 cron job 运行（或手动触发）
3. 检查 parent 是否收到通知

**预期结果:**
- Parent 收到通知: "Alice Smith has been inactive for 3 days"

### 测试 3: 避免重复通知

1. 确保同一作业/不活动已经创建了通知
2. 再次运行 cron job
3. 检查是否创建了重复通知

**预期结果:**
- 不会创建重复通知（检查 existingNotification）

## 完整测试脚本 (PowerShell)

```powershell
$BASE_URL = "http://localhost:3000/api"

# 1. 注册 Parent
Write-Host "1. Registering parent..." -ForegroundColor Yellow
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

# 2. 创建 Kid
Write-Host "`n2. Creating kid..." -ForegroundColor Yellow
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

# 3. 查看通知
Write-Host "`n3. Viewing notifications..." -ForegroundColor Yellow
$notifications = Invoke-RestMethod -Uri "$BASE_URL/notifications" `
    -Method Get `
    -Headers $parentHeaders

Write-Host "Total notifications: $($notifications.Count)" -ForegroundColor Green
$notifications | ConvertTo-Json -Depth 10

# 4. 查看未读通知
Write-Host "`n4. Viewing unread notifications..." -ForegroundColor Yellow
$unreadNotifications = Invoke-RestMethod -Uri "$BASE_URL/notifications?status=unread" `
    -Method Get `
    -Headers $parentHeaders

Write-Host "Unread notifications: $($unreadNotifications.Count)" -ForegroundColor Green
$unreadNotifications | ConvertTo-Json -Depth 10

# 5. 标记通知为已读（如果有通知）
if ($unreadNotifications.Count -gt 0) {
    Write-Host "`n5. Marking notification as read..." -ForegroundColor Yellow
    $notificationId = $unreadNotifications[0].id
    
    $readResponse = Invoke-RestMethod -Uri "$BASE_URL/notifications/$notificationId/read" `
        -Method Patch `
        -Headers $parentHeaders
    
    Write-Host "Notification marked as read" -ForegroundColor Green
    $readResponse | ConvertTo-Json
}

Write-Host "`n✅ All tests completed!" -ForegroundColor Green
```

## 测试场景清单

- [ ] Parent 可以查看自己的通知
- [ ] Teacher 可以查看自己的通知
- [ ] 可以过滤未读/已读通知
- [ ] 可以标记通知为已读
- [ ] 作业到期前24小时创建通知
- [ ] 3天不活动创建通知
- [ ] 不会创建重复通知
- [ ] 旧通知被清理（30天前已读）

## Cron 计划说明

### 作业到期检查 (每6小时)

```typescript
@Cron('0 */6 * * *', {
  name: 'checkAssignmentDue',
  timeZone: 'UTC',
})
```

**执行时间**: 每天 00:00, 06:00, 12:00, 18:00 (UTC)

### 不活动检查 (每天凌晨2点)

```typescript
@Cron('0 2 * * *', {
  name: 'checkInactivity',
  timeZone: 'UTC',
})
```

**执行时间**: 每天 02:00 (UTC)

### 清理旧通知 (每天凌晨3点)

```typescript
@Cron('0 3 * * *', {
  name: 'cleanupOldNotifications',
  timeZone: 'UTC',
})
```

**执行时间**: 每天 03:00 (UTC)

## 注意事项

1. **Cron Jobs**: 需要服务器持续运行才能执行
2. **时区**: 所有 cron jobs 使用 UTC 时区
3. **重复通知**: 系统会检查并避免创建重复通知
4. **通知清理**: 只清理30天前已读的通知，未读通知不会被清理
5. **Assignment 创建**: 需要手动创建或通过 API（如果实现了）

## 手动测试 Cron Jobs

如果需要手动测试 cron jobs，可以在代码中添加测试端点或使用 NestJS 的 SchedulerRegistry：

```typescript
// 在控制器中添加测试端点（仅用于开发）
@Post('test/assignment-due')
async testAssignmentDue() {
  await this.notificationsService.checkAssignmentDueNotifications();
  return { message: 'Assignment due check completed' };
}
```
