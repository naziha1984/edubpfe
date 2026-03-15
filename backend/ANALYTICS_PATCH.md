# Analytics 完整补丁总结

## 📦 新增文件

```
backend/src/analytics/
├── analytics.service.ts        # Analytics 服务（MongoDB aggregation）
├── analytics.controller.ts      # Analytics 控制器
└── analytics.module.ts          # Analytics 模块
```

## 🔧 功能实现

### 1. API 端点

#### GET /api/teacher/classes/:classId/subjects/:subjectId/progress

获取班级中某个科目的进度统计

**要求:**
- 需要 TEACHER 角色
- 严格所有权检查：只能查看自己的班级

**返回数据:**
- `classId`: 班级 ID
- `subjectId`: 科目 ID
- `kids`: 每个 kid 的统计信息数组
- `overallStats`: 整体统计信息

### 2. Kid 统计信息

每个 kid 包含：
- `kidId`: Kid ID
- `kidName`: Kid 全名（firstName + lastName）
- `avgScore`: 平均分数（基于 bestScore）
- `lastActivity`: 最后活动时间（lastAttemptAt 的最大值）
- `completionRate`: 完成率百分比
- `totalLessons`: 总 lessons 数
- `completedLessons`: 已完成的 lessons 数

### 3. 整体统计信息

- `totalKids`: 班级总 kid 数
- `averageScore`: 所有有进度的 kids 的平均分数平均值
- `overallCompletionRate`: 所有有进度的 kids 的完成率平均值

## 🔒 严格所有权检查

```typescript
// 验证班级所有权
const isOwner = await this.classesService.checkOwnership(classId, teacherId);
if (!isOwner) {
  throw new ForbiddenException('You can only view analytics for your own classes');
}
```

## 📊 MongoDB Aggregation Pipeline

### Pipeline 阶段

1. **$match**: 匹配指定班级 kids 和指定 subject 的 Progress 记录
2. **$group**: 按 kidId 分组，计算统计信息
3. **$lookup**: 关联 Kid 集合获取 kid 信息
4. **$unwind**: 展开 kid 数组
5. **$project**: 投影最终结构

### 详细 Pipeline

```typescript
[
  {
    $match: {
      kidId: { $in: kidIds },
      subjectId: new Types.ObjectId(subjectId),
    },
  },
  {
    $group: {
      _id: '$kidId',
      avgScore: { $avg: '$bestScore' },
      maxLastActivity: { $max: '$lastAttemptAt' },
      completedCount: {
        $sum: { $cond: ['$isCompleted', 1, 0] },
      },
      totalLessons: { $sum: 1 },
    },
  },
  {
    $lookup: {
      from: 'kids',
      localField: '_id',
      foreignField: '_id',
      as: 'kid',
    },
  },
  {
    $unwind: {
      path: '$kid',
      preserveNullAndEmptyArrays: true,
    },
  },
  {
    $project: {
      kidId: { $toString: '$_id' },
      kidName: {
        $concat: [
          { $ifNull: ['$kid.firstName', ''] },
          ' ',
          { $ifNull: ['$kid.lastName', ''] },
        ],
      },
      avgScore: { $round: [{ $ifNull: ['$avgScore', 0] }, 2] },
      lastActivity: '$maxLastActivity',
      completedLessons: '$completedCount',
      totalLessons: '$totalLessons',
      completionRate: {
        $cond: [
          { $gt: ['$totalLessons', 0] },
          {
            $round: [
              {
                $multiply: [
                  { $divide: ['$completedCount', '$totalLessons'] },
                  100,
                ],
              },
              2,
            ],
          },
          0,
        ],
      },
    },
  },
]
```

## 📝 计算逻辑

### avgScore（平均分数）

```typescript
avgScore: { $avg: '$bestScore' }
```

- 计算该 kid 在该 subject 所有 lessons 的 bestScore 平均值
- 四舍五入到 2 位小数

### lastActivity（最后活动时间）

```typescript
maxLastActivity: { $max: '$lastAttemptAt' }
```

- 获取该 kid 在该 subject 所有 Progress 记录中 lastAttemptAt 的最大值
- 如果没有活动，返回 null

### completionRate（完成率）

```typescript
completionRate: (completedLessons / totalLessons) * 100
```

- `completedLessons`: isCompleted = true 的记录数
- `totalLessons`: 该 kid 在该 subject 的总 Progress 记录数
- 百分比，四舍五入到 2 位小数

### overallStats（整体统计）

```typescript
// 只计算有进度的 kids
const kidsWithProgress = kids.filter((k) => k.totalLessons > 0);

// 平均分数
averageScore = sum(avgScore) / kidsWithProgress.length

// 整体完成率
overallCompletionRate = sum(completionRate) / kidsWithProgress.length
```

## 🚀 API 端点总结

| 方法 | 路径 | 描述 | 认证 | 所有权检查 |
|------|------|------|------|-----------|
| GET | /api/teacher/classes/:classId/subjects/:subjectId/progress | 获取班级科目进度统计 | TEACHER | ✅ 班级所有者 |

## ✅ 测试场景

- [x] Teacher 可以查看自己班级的 analytics
- [x] Teacher 不能查看其他 Teacher 的班级 analytics（403）
- [x] 非 TEACHER 用户不能访问（403）
- [x] 空班级返回空数组
- [x] 有成员但无进度数据时返回 0 值
- [x] avgScore 计算正确
- [x] lastActivity 显示最新活动时间
- [x] completionRate 计算正确
- [x] overallStats 计算正确

## 📚 JSON 响应示例

### 完整响应

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
    }
  ],
  "overallStats": {
    "totalKids": 2,
    "averageScore": 88.75,
    "overallCompletionRate": 87.5
  }
}
```

### 空数据响应

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

## 🔍 技术细节

### 数据源

- **ClassMembership**: 获取班级成员列表
- **Progress**: 获取每个 kid 的进度数据
- **Kid**: 获取 kid 的姓名信息

### 处理逻辑

1. **获取班级成员**: 查询 ClassMembership 获取所有活跃成员
2. **聚合进度数据**: 使用 aggregation 计算每个 kid 的统计信息
3. **合并数据**: 将聚合结果与成员列表合并，确保所有成员都出现在结果中
4. **计算整体统计**: 基于有进度的 kids 计算平均值

### 性能优化

- 使用 MongoDB aggregation 在数据库层面计算，减少应用层处理
- 使用索引优化查询性能（kidId, subjectId）
- 一次性获取所有数据，避免 N+1 查询问题

## 📚 相关文档

- `ANALYTICS_TEST.md`: 详细测试指南
- `CLASSES_TEST.md`: Classes 模块测试
- `QUIZ_TEST.md`: Quiz 模块测试

## ⚠️ 注意事项

1. **所有权检查**: 严格验证 teacher 拥有该班级
2. **空值处理**: 无进度数据的 kid 显示 0 值，lastActivity 为 null
3. **完成率**: 基于 isCompleted 字段，不是基于分数
4. **平均分数**: 基于 bestScore，不是最新分数
5. **整体统计**: 只计算有进度的 kids，不包括无进度的 kids

## 🔐 安全保证

1. **角色验证**: 需要 TEACHER 角色
2. **所有权验证**: 严格检查班级所有权
3. **数据隔离**: Teacher 只能查看自己的班级数据
4. **输入验证**: 验证 classId 和 subjectId 格式
