# Notifications 完整补丁总结

## 📦 新增文件

```
backend/src/notifications/
├── schemas/
│   ├── notification.schema.ts    # Notification schema
│   └── assignment.schema.ts       # Assignment schema（用于作业到期通知）
├── notifications.service.ts       # Notifications 服务（通知规则和生成逻辑）
├── notifications.controller.ts    # Notifications 控制器
├── notifications.cron.ts          # Cron jobs（定期检查通知）
└── notifications.module.ts        # Notifications 模块
```

## 🔧 功能实现

### 1. Notification Schema

**字段:**
- `userId`: 接收通知的用户 ID（ObjectId）
- `type`: 通知类型（ASSIGNMENT_DUE_24H, INACTIVITY_3_DAYS）
- `status`: 通知状态（UNREAD, READ）
- `title`: 通知标题
- `message`: 通知消息
- `kidId`: 关联的 kid ID（可选）
- `relatedId`: 关联的实体 ID（assignment, class, etc.）
- `relatedType`: 关联的实体类型
- `readAt`: 已读时间
- `timestamps`: 自动添加 createdAt 和 updatedAt

**索引:**
- `{ userId: 1, status: 1, createdAt: -1 }`: 用于查询用户的通知
- `{ userId: 1, type: 1 }`: 用于查询特定类型的通知

### 2. Assignment Schema

**字段:**
- `classId`: 班级 ID（ObjectId）
- `teacherId`: 教师 ID（ObjectId）
- `title`: 作业标题
- `description`: 作业描述
- `lessonId`: 关联的课程 ID（可选）
- `dueDate`: 到期日期
- `isActive`: 是否活跃

**索引:**
- `{ classId: 1, dueDate: 1 }`: 用于查询班级的作业
- `{ teacherId: 1 }`: 用于查询教师的作业

### 3. 通知规则

#### 规则 1: 作业到期前24小时

**触发条件:**
- 作业的 `dueDate` 在24小时内
- 作业是活跃的（`isActive: true`）

**通知对象:**
- Parent（kid 的 parent）
- Teacher（作业的创建者）

**通知内容:**
- Parent: "Assignment \"{title}\" is due in less than 24 hours for {kidName}"
- Teacher: "Assignment \"{title}\" is due in less than 24 hours. Student: {kidName}"

**实现逻辑:**
```typescript
const now = new Date();
const in24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);

const assignments = await this.assignmentModel.find({
  dueDate: { $gte: now, $lte: in24Hours },
  isActive: true,
});
```

#### 规则 2: 3天不活动

**触发条件:**
- Kid 的最后活动（Progress.lastAttemptAt）超过3天
- 如果没有 Progress 记录，使用 kid.createdAt

**通知对象:**
- Parent（kid 的 parent）

**通知内容:**
- "{kidName} has been inactive for 3 days"

**实现逻辑:**
```typescript
const threeDaysAgo = new Date();
threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);

const lastProgress = await this.progressModel
  .findOne({ kidId: kid._id })
  .sort({ lastAttemptAt: -1 });

const lastActivity = lastProgress?.lastAttemptAt || kid.createdAt;

if (lastActivity < threeDaysAgo) {
  // 创建通知
}
```

### 4. Cron Jobs

#### Cron Job 1: 作业到期检查

```typescript
@Cron('0 */6 * * *', {
  name: 'checkAssignmentDue',
  timeZone: 'UTC',
})
```

- **频率**: 每6小时
- **执行时间**: 00:00, 06:00, 12:00, 18:00 (UTC)
- **功能**: 检查24小时内到期的作业，创建通知

#### Cron Job 2: 不活动检查

```typescript
@Cron('0 2 * * *', {
  name: 'checkInactivity',
  timeZone: 'UTC',
})
```

- **频率**: 每天凌晨2点
- **执行时间**: 02:00 (UTC)
- **功能**: 检查3天不活动的 kids，创建通知

#### Cron Job 3: 清理旧通知

```typescript
@Cron('0 3 * * *', {
  name: 'cleanupOldNotifications',
  timeZone: 'UTC',
})
```

- **频率**: 每天凌晨3点
- **执行时间**: 03:00 (UTC)
- **功能**: 删除30天前已读的通知

### 5. 防重复机制

**检查逻辑:**
```typescript
const existingNotification = await this.notificationModel.findOne({
  userId: userId,
  type: NotificationType.ASSIGNMENT_DUE_24H,
  relatedId: assignment._id,
  status: NotificationStatus.UNREAD,
});
```

**避免重复:**
- 检查是否已有相同类型、相同相关实体的未读通知
- 如果有，不创建新通知

## 🚀 API 端点

### GET /api/notifications

获取通知列表（需要 PARENT 或 TEACHER 角色）

**认证**: JWT (parentToken 或 teacherToken)
**查询参数**:
- `status` (可选): `unread` 或 `read` 过滤通知

**响应:**
```json
[
  {
    "id": "...",
    "type": "ASSIGNMENT_DUE_24H",
    "status": "UNREAD",
    "title": "Assignment Due Soon",
    "message": "...",
    "kidId": "...",
    "relatedId": "...",
    "relatedType": "assignment",
    "readAt": null,
    "createdAt": "...",
    "updatedAt": "..."
  }
]
```

### PATCH /api/notifications/:id/read

标记通知为已读

**认证**: JWT (parentToken 或 teacherToken)
**所有权检查**: 只能标记自己的通知

**响应:**
```json
{
  "id": "...",
  "status": "READ",
  "readAt": "..."
}
```

## 🔒 安全特性

1. **角色验证**: 需要 PARENT 或 TEACHER 角色
2. **所有权验证**: 只能查看和标记自己的通知
3. **数据隔离**: 用户只能看到自己的通知

## 📊 数据模型关系

```
User (Parent/Teacher)
  └── Notification (userId)
       ├── Kid (kidId, optional)
       └── Assignment (relatedId, optional)

Assignment
  ├── Class (classId)
  └── Teacher (teacherId)

Kid
  └── Parent (parentId)
  └── Progress (lastAttemptAt)
```

## 🔄 集成点

### AppModule 更新

```typescript
imports: [
  // ...
  NotificationsModule,  // 新增
]
```

### Package.json 更新

```json
{
  "dependencies": {
    "@nestjs/schedule": "^4.0.0"  // 新增
  },
  "devDependencies": {
    "@types/cron": "^2.0.0"  // 新增
  }
}
```

## 📝 Cron 计划总结

| Cron Job | 频率 | 时间 (UTC) | 功能 |
|----------|------|-----------|------|
| checkAssignmentDue | 每6小时 | 00:00, 06:00, 12:00, 18:00 | 检查作业到期 |
| checkInactivity | 每天 | 02:00 | 检查不活动 |
| cleanupOldNotifications | 每天 | 03:00 | 清理旧通知 |

## ✅ 测试场景

- [x] Parent 可以查看自己的通知
- [x] Teacher 可以查看自己的通知
- [x] 可以过滤未读/已读通知
- [x] 可以标记通知为已读
- [x] 作业到期前24小时创建通知
- [x] 3天不活动创建通知
- [x] 不会创建重复通知
- [x] 旧通知被清理（30天前已读）

## 📚 相关文档

- `NOTIFICATIONS_TEST.md`: 详细测试指南
- `CLASSES_TEST.md`: Classes 模块测试
- `QUIZ_TEST.md`: Quiz 模块测试

## ⚠️ 注意事项

1. **Cron Jobs**: 需要服务器持续运行才能执行
2. **时区**: 所有 cron jobs 使用 UTC 时区
3. **重复通知**: 系统会检查并避免创建重复通知
4. **通知清理**: 只清理30天前已读的通知，未读通知不会被清理
5. **Assignment 创建**: 需要手动创建或通过 API（如果实现了）
6. **依赖**: 需要安装 `@nestjs/schedule` 包

## 🔐 安全保证

1. **角色验证**: 需要 PARENT 或 TEACHER 角色
2. **所有权验证**: 只能查看和标记自己的通知
3. **数据隔离**: 用户只能看到自己的通知
4. **输入验证**: 验证 notificationId 格式

## 🎯 通知类型

### ASSIGNMENT_DUE_24H
- **触发**: 作业在24小时内到期
- **接收者**: Parent, Teacher
- **消息**: 包含作业标题和 kid 名称

### INACTIVITY_3_DAYS
- **触发**: Kid 3天没有活动
- **接收者**: Parent
- **消息**: 包含 kid 名称

## 🔧 扩展性

### 添加新通知类型

1. 在 `NotificationType` enum 中添加新类型
2. 在 `NotificationsService` 中添加检查逻辑
3. 在 `NotificationsCron` 中添加 cron job（如果需要）

### 自定义 Cron 计划

修改 `@Cron()` 装饰器中的 cron 表达式：
- `'0 */6 * * *'`: 每6小时
- `'0 2 * * *'`: 每天凌晨2点
- `'0 0 * * 1'`: 每周一凌晨
