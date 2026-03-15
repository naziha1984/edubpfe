# QuizModule 完整补丁总结

## 📦 新增文件

```
backend/src/quiz/
├── schemas/
│   ├── quiz-session.schema.ts   # QuizSession schema
│   ├── progress.schema.ts       # Progress schema（唯一索引）
│   └── quiz-question.schema.ts  # QuizQuestion schema
├── dto/
│   ├── create-session.dto.ts   # 创建会话 DTO
│   └── submit-quiz.dto.ts      # 提交答案 DTO
├── guards/
│   └── progress-auth.guard.ts  # Progress 认证守卫（未使用，保留备用）
├── quiz.service.ts             # Quiz 服务（严格 IDOR 保护）
├── progress.service.ts         # Progress 服务（严格 IDOR 保护）
├── quiz.controller.ts          # Quiz 控制器
├── progress.controller.ts      # Progress 控制器
└── quiz.module.ts              # Quiz 模块
```

## 🔧 功能实现

### 1. QuizSession Schema

**字段:**
- `kidId`: Kid 引用（ObjectId）
- `lessonId`: Lesson 引用（ObjectId）
- `status`: 状态（in_progress | completed）
- `score`: 分数
- `totalQuestions`: 总题目数
- `completedAt`: 完成时间
- `timestamps`: 自动添加 createdAt 和 updatedAt

### 2. Progress Schema

**字段:**
- `kidId`: Kid 引用（ObjectId）
- `lessonId`: Lesson 引用（ObjectId）
- `subjectId`: Subject 引用（ObjectId）
- `bestScore`: 最佳分数
- `attempts`: 尝试次数
- `isCompleted`: 是否完成（分数 >= 80%）
- `lastAttemptAt`: 最后尝试时间
- `timestamps`: 自动添加 createdAt 和 updatedAt

**唯一索引:**
- 复合唯一索引: `{ kidId: 1, lessonId: 1 }` - 确保每个 kid 对每个 lesson 只有一个进度记录

### 3. QuizQuestion Schema

**字段:**
- `lessonId`: Lesson 引用（ObjectId）
- `question`: 问题文本
- `options`: 选项数组
- `correctAnswer`: 正确答案索引
- `explanation`: 解释
- `isActive`: 是否活跃

### 4. API 端点

#### POST /api/quiz/sessions
- 创建测验会话
- 需要 kidToken
- **严格 IDOR 检查**: kidId 必须与 token 中的 kidId 匹配
- 自动创建或更新 Progress

#### POST /api/quiz/submit
- 提交答案并计算分数
- 需要 kidToken
- **严格 IDOR 检查**: session 必须属于 token 中的 kid
- 更新 Progress（bestScore, attempts, isCompleted）

#### GET /api/progress/kids/:kidId
- Kid 查看自己的进度
- 需要 kidToken
- **严格 IDOR 检查**: kidId 必须与 token 中的 kidId 匹配

#### GET /api/progress/parent/kids/:kidId
- Parent 查看 kid 的进度
- 需要 parentToken (PARENT 角色)
- **严格 IDOR 检查**: kid 必须属于 parent

## 🔒 严格 IDOR 保护

### 1. 创建会话保护

```typescript
// kidId from token must match kidId from request
if (createSessionDto.kidId !== kidIdFromToken) {
  throw new ForbiddenException('You can only create sessions for yourself');
}
```

### 2. 提交答案保护

```typescript
// Session must belong to the kid from token
if (session.kidId.toString() !== kidIdFromToken) {
  throw new ForbiddenException('You can only submit quizzes for your own sessions');
}
```

### 3. 进度查看保护

**Kid 访问:**
```typescript
if (kidId !== requesterKidId) {
  throw new ForbiddenException('You can only view your own progress');
}
```

**Parent 访问:**
```typescript
if (kid.parentId.toString() !== requesterParentId) {
  throw new ForbiddenException('You can only view progress for your own kids');
}
```

## 📝 业务逻辑

### 1. 分数计算

- 比较每个答案的 `selectedAnswer` 与 `correctAnswer`
- 计算正确数量
- 计算百分比: `(score / totalQuestions) * 100`

### 2. 进度更新

- `attempts`: 每次提交 +1
- `bestScore`: 如果新分数更高则更新
- `isCompleted`: 如果百分比 >= 80% 则标记为完成
- `lastAttemptAt`: 更新为当前时间

### 3. 会话状态

- 创建时: `status = 'in_progress'`
- 提交后: `status = 'completed'`, 设置 `completedAt`

## 🚀 API 端点总结

| 方法 | 路径 | 描述 | 认证 | IDOR 保护 |
|------|------|------|------|-----------|
| POST | /api/quiz/sessions | 创建会话 | kidToken | ✅ kidId 匹配 |
| POST | /api/quiz/submit | 提交答案 | kidToken | ✅ session 所有权 |
| GET | /api/progress/kids/:kidId | Kid 查看进度 | kidToken | ✅ kidId 匹配 |
| GET | /api/progress/parent/kids/:kidId | Parent 查看进度 | parentToken | ✅ kid 所有权 |

## ✅ 测试场景

- [x] Kid 创建自己的会话
- [x] Kid 不能创建其他 kid 的会话（403）
- [x] Kid 提交自己的会话答案
- [x] Kid 不能提交其他 kid 的会话（403）
- [x] 分数计算正确
- [x] 进度正确更新
- [x] Kid 查看自己的进度
- [x] Kid 不能查看其他 kid 的进度（403）
- [x] Parent 查看自己 kid 的进度
- [x] Parent 不能查看其他 parent 的 kid 进度（403）
- [x] 会话完成后不能再次提交（400）

## 🔍 技术细节

### 唯一索引

```typescript
// Progress: 每个 kid 对每个 lesson 只有一个进度记录
ProgressSchema.index({ kidId: 1, lessonId: 1 }, { unique: true });
```

### 进度创建/更新

```typescript
// Upsert: 如果不存在则创建，存在则更新
const progress = await this.progressModel.findOneAndUpdate(
  { kidId, lessonId },
  { kidId, lessonId, subjectId },
  { upsert: true, new: true }
);
```

### 分数计算

```typescript
let correctAnswers = 0;
submitQuizDto.answers.forEach((answer) => {
  const question = questions[answer.questionIndex];
  if (question && question.correctAnswer === answer.selectedAnswer) {
    correctAnswers++;
  }
});
```

## 📚 相关文档

- `QUIZ_TEST.md`: 详细测试指南
- `KIDS_TEST.md`: Kids 模块测试
- `PIN_TEST.md`: PIN 功能测试

## ⚠️ 注意事项

1. **IDOR 保护**: 所有端点都严格验证所有权
2. **kidToken 验证**: kidId 必须与 token 中的 kidId 匹配
3. **进度更新**: 分数 >= 80% 时标记为完成
4. **最佳分数**: 自动更新为最高分数
5. **尝试次数**: 每次提交增加计数
6. **会话状态**: 完成后不能再次提交
7. **题目要求**: 提交答案前需要先创建 QuizQuestion

## 🔐 安全保证

1. **Token 验证**: 所有端点都需要有效的 kidToken 或 parentToken
2. **所有权验证**: 严格检查资源所有权
3. **角色验证**: Parent 端点需要 PARENT 角色
4. **数据隔离**: Kid 只能访问自己的数据
5. **Parent 限制**: Parent 只能访问自己 kids 的数据
