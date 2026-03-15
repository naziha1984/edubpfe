# Analytics JSON 响应示例

## 完整响应示例

### 示例 1: 有完整数据的响应

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
      "avgScore": 78.25,
      "lastActivity": "2026-02-09T10:20:00.000Z",
      "completionRate": 50.0,
      "totalLessons": 4,
      "completedLessons": 2
    }
  ],
  "overallStats": {
    "totalKids": 3,
    "averageScore": 85.25,
    "overallCompletionRate": 75.0
  }
}
```

**说明:**
- 3 个 kids 都有进度数据
- Alice: 平均分 85.5，完成率 75%（3/4）
- Bob: 平均分 92.0，完成率 100%（4/4）
- Charlie: 平均分 78.25，完成率 50%（2/4）
- 整体平均分: (85.5 + 92.0 + 78.25) / 3 = 85.25
- 整体完成率: (75.0 + 100.0 + 50.0) / 3 = 75.0

### 示例 2: 部分 kids 有进度数据

```json
{
  "classId": "507f1f77bcf86cd799439011",
  "subjectId": "507f191e810c19729de860ea",
  "kids": [
    {
      "kidId": "507f1f77bcf86cd799439012",
      "kidName": "Alice Smith",
      "avgScore": 88.0,
      "lastActivity": "2026-02-10T15:30:00.000Z",
      "completionRate": 80.0,
      "totalLessons": 5,
      "completedLessons": 4
    },
    {
      "kidId": "507f1f77bcf86cd799439013",
      "kidName": "Bob Johnson",
      "avgScore": 0,
      "lastActivity": null,
      "completionRate": 0,
      "totalLessons": 0,
      "completedLessons": 0
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
    "averageScore": 88.0,
    "overallCompletionRate": 80.0
  }
}
```

**说明:**
- Alice 有进度数据（平均分 88.0，完成率 80%）
- Bob 和 Charlie 没有进度数据（显示 0 值）
- 整体统计只计算有进度的 kids（Alice）
- 整体平均分: 88.0
- 整体完成率: 80.0

### 示例 3: 空班级

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

**说明:**
- 班级没有成员
- kids 数组为空
- 所有统计值为 0

### 示例 4: 有成员但无进度数据

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
    },
    {
      "kidId": "507f1f77bcf86cd799439013",
      "kidName": "Bob Johnson",
      "avgScore": 0,
      "lastActivity": null,
      "completionRate": 0,
      "totalLessons": 0,
      "completedLessons": 0
    }
  ],
  "overallStats": {
    "totalKids": 2,
    "averageScore": 0,
    "overallCompletionRate": 0
  }
}
```

**说明:**
- 班级有 2 个成员
- 但都没有该科目的进度数据
- 所有统计值为 0

### 示例 5: 混合场景（部分完成）

```json
{
  "classId": "507f1f77bcf86cd799439011",
  "subjectId": "507f191e810c19729de860ea",
  "kids": [
    {
      "kidId": "507f1f77bcf86cd799439012",
      "kidName": "Alice Smith",
      "avgScore": 95.0,
      "lastActivity": "2026-02-10T18:00:00.000Z",
      "completionRate": 100.0,
      "totalLessons": 6,
      "completedLessons": 6
    },
    {
      "kidId": "507f1f77bcf86cd799439013",
      "kidName": "Bob Johnson",
      "avgScore": 72.5,
      "lastActivity": "2026-02-08T14:20:00.000Z",
      "completionRate": 33.33,
      "totalLessons": 6,
      "completedLessons": 2
    },
    {
      "kidId": "507f1f77bcf86cd799439014",
      "kidName": "Charlie Brown",
      "avgScore": 0,
      "lastActivity": null,
      "completionRate": 0,
      "totalLessons": 0,
      "completedLessons": 0
    },
    {
      "kidId": "507f1f77bcf86cd799439015",
      "kidName": "Diana Prince",
      "avgScore": 87.75,
      "lastActivity": "2026-02-10T17:30:00.000Z",
      "completionRate": 83.33,
      "totalLessons": 6,
      "completedLessons": 5
    }
  ],
  "overallStats": {
    "totalKids": 4,
    "averageScore": 85.08,
    "overallCompletionRate": 72.22
  }
}
```

**说明:**
- 4 个 kids，3 个有进度数据
- Alice: 100% 完成，平均分 95.0
- Bob: 33.33% 完成，平均分 72.5
- Charlie: 无进度数据
- Diana: 83.33% 完成，平均分 87.75
- 整体平均分: (95.0 + 72.5 + 87.75) / 3 = 85.08
- 整体完成率: (100.0 + 33.33 + 83.33) / 3 = 72.22

## 字段说明

### kid 对象字段

| 字段 | 类型 | 说明 |
|------|------|------|
| kidId | string | Kid 的 ID |
| kidName | string | Kid 的全名（firstName + lastName） |
| avgScore | number | 平均分数（基于 bestScore，保留 2 位小数） |
| lastActivity | Date \| null | 最后活动时间（lastAttemptAt 的最大值） |
| completionRate | number | 完成率百分比（0-100，保留 2 位小数） |
| totalLessons | number | 该 kid 在该 subject 的总 lessons 数 |
| completedLessons | number | 已完成的 lessons 数（isCompleted = true） |

### overallStats 对象字段

| 字段 | 类型 | 说明 |
|------|------|------|
| totalKids | number | 班级总 kid 数 |
| averageScore | number | 所有有进度的 kids 的平均分数平均值 |
| overallCompletionRate | number | 所有有进度的 kids 的完成率平均值 |

## 计算规则

### avgScore
- 计算方式: `AVG(bestScore)` 对于该 kid 在该 subject 的所有 Progress 记录
- 示例: 如果 kid 有 4 个 lessons，bestScore 分别为 [80, 90, 85, 87]，则 avgScore = (80+90+85+87)/4 = 85.5

### completionRate
- 计算方式: `(completedLessons / totalLessons) * 100`
- 示例: 如果 totalLessons = 4，completedLessons = 3，则 completionRate = (3/4) * 100 = 75.0

### overallStats.averageScore
- 计算方式: 只计算有进度的 kids（totalLessons > 0）
- 示例: 如果有 3 个 kids，avgScore 分别为 [85.5, 92.0, 78.25]，则 averageScore = (85.5+92.0+78.25)/3 = 85.25

### overallStats.overallCompletionRate
- 计算方式: 只计算有进度的 kids（totalLessons > 0）
- 示例: 如果有 3 个 kids，completionRate 分别为 [75.0, 100.0, 50.0]，则 overallCompletionRate = (75.0+100.0+50.0)/3 = 75.0

## 错误响应示例

### 403 Forbidden - 不是班级所有者

```json
{
  "statusCode": 403,
  "message": "You can only view analytics for your own classes",
  "timestamp": "2026-02-10T20:00:00.000Z",
  "path": "/api/teacher/classes/.../subjects/.../progress",
  "method": "GET"
}
```

### 404 Not Found - 班级不存在

```json
{
  "statusCode": 404,
  "message": "Class not found",
  "timestamp": "2026-02-10T20:00:00.000Z",
  "path": "/api/teacher/classes/.../subjects/.../progress",
  "method": "GET"
}
```

### 403 Forbidden - 非 TEACHER 角色

```json
{
  "statusCode": 403,
  "message": "Forbidden resource",
  "timestamp": "2026-02-10T20:00:00.000Z",
  "path": "/api/teacher/classes/.../subjects/.../progress",
  "method": "GET"
}
```
