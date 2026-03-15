# Gamification (Rewards) 完整补丁总结

## 📦 新增文件

```
backend/src/rewards/
├── schemas/
│   ├── reward.schema.ts           # Reward schema（XP, Level, Streak, Badges）
│   ├── badge.schema.ts            # Badge schema（徽章定义）
│   └── reward-history.schema.ts   # RewardHistory schema（XP 历史记录）
├── rewards.service.ts              # Rewards 服务（XP, Badges, Streaks 逻辑）
├── badge.service.ts                # Badge 服务（徽章管理）
├── rewards.controller.ts           # Rewards 控制器
├── rewards.module.ts               # Rewards 模块
└── scripts/
    └── seed-badges.ts              # Badge seed 脚本
```

## 🔧 功能实现

### 1. XP 系统

#### Quiz XP 奖励
- **基础 XP**: 50 XP（完成测验）
- **分数奖励**: `(score / totalQuestions) * 50`（最多 50 XP）
- **总 XP**: 基础 XP + 分数奖励（最多 100 XP）

**实现位置**: `QuizService.submitQuiz()`

```typescript
const baseXP = 50;
const scoreBonus = Math.round((score / totalQuestions) * 50);
const totalXP = baseXP + scoreBonus;

await this.rewardsService.addXP(
  kidIdFromToken,
  totalXP,
  'quiz',
  session._id.toString(),
  `Quiz completed: ${score}/${totalQuestions} (${percentage}%)`,
);
```

#### Streak XP 奖励
- **第一天**: 10 XP
- **连续天数**: 10 + (streak * 2) XP
- **示例**: 
  - Day 1: 10 XP
  - Day 2: 14 XP (10 + 2*2)
  - Day 7: 24 XP (10 + 7*2)

**实现位置**: `RewardsService.updateStreak()`

### 2. Level 系统

- **每级需要**: 1000 XP
- **Level 计算**: `Math.floor(totalXP / 1000)`
- **下一级所需 XP**: `1000 - (totalXP % 1000)`

### 3. Badge 系统

#### Badge 类型

| Badge Type | 名称 | 描述 | 触发条件 |
|------------|------|------|----------|
| QUIZ_MASTER | Quiz Master | 完成 10 个测验 | 完成 10 个 quiz |
| PERFECT_SCORE | Perfect Score | 获得 100% 分数 | 单次 quiz 100% |
| STREAK_7 | Week Warrior | 7 天连续签到 | 连续 7 天 streak |
| STREAK_30 | Monthly Champion | 30 天连续签到 | 连续 30 天 streak |
| XP_1000 | XP Explorer | 达到 1000 XP | 总 XP >= 1000 |
| XP_5000 | XP Master | 达到 5000 XP | 总 XP >= 5000 |

#### Badge 自动授予
- 满足条件时自动授予
- 不会重复授予（检查 `reward.badges` 数组）
- 在以下时机检查：
  - Quiz 提交后（Perfect Score, Quiz Master）
  - Streak 更新后（Streak 7, Streak 30）
  - XP 增加后（XP 1000, XP 5000）

### 4. Streak 系统

#### Streak 逻辑
- **首次签到**: streak = 1，获得 10 XP
- **连续签到**: streak += 1，获得 10 + (streak * 2) XP
- **中断签到**: streak 重置为 1，获得 10 XP
- **同一天重复签到**: 返回 0 XP，不更新 streak

**实现位置**: `RewardsService.updateStreak()`

```typescript
const today = new Date();
today.setHours(0, 0, 0, 0);

const lastStreakDate = reward.lastStreakDate
  ? new Date(reward.lastStreakDate)
  : null;

if (lastStreakDate) {
  lastStreakDate.setHours(0, 0, 0, 0);
}

if (!lastStreakDate) {
  // First streak
  reward.currentStreak = 1;
  reward.lastStreakDate = today;
  xpEarned = 10;
} else {
  const daysDiff = Math.floor(
    (today.getTime() - lastStreakDate.getTime()) / (1000 * 60 * 60 * 24),
  );

  if (daysDiff === 0) {
    // Already checked in today
    return { streak: reward.currentStreak, xpEarned: 0 };
  } else if (daysDiff === 1) {
    // Consecutive day
    reward.currentStreak += 1;
    reward.lastStreakDate = today;
    xpEarned = 10 + reward.currentStreak * 2;
  } else {
    // Streak broken
    reward.currentStreak = 1;
    reward.lastStreakDate = today;
    xpEarned = 10;
  }
}
```

## 🚀 API 端点

### GET /api/kids/:kidId/rewards

Parent 查看 kid 的奖励（需要 PARENT 角色）

**认证**: JWT (parentToken)
**所有权检查**: 严格验证 parent 拥有该 kid

**响应:**
```json
{
  "kidId": "...",
  "totalXP": 150,
  "currentLevel": 0,
  "xpForNextLevel": 850,
  "currentStreak": 2,
  "lastStreakDate": "2026-02-10T00:00:00.000Z",
  "badges": [...],
  "recentHistory": [...]
}
```

### GET /api/kid/rewards

Kid 查看自己的奖励（需要 kidToken）

**认证**: Kid JWT (kidToken)
**所有权检查**: kidToken 中的 kidId 自动匹配

**响应**: 同上

### POST /api/kid/streak

Kid 更新每日 streak（需要 kidToken）

**认证**: Kid JWT (kidToken)
**响应:**
```json
{
  "streak": 2,
  "xpEarned": 14,
  "message": "Streak updated! Current streak: 2 days. Earned 14 XP."
}
```

## 🔒 严格所有权检查

### Parent 端点
```typescript
// 验证 kid 属于 parent
const kid = await this.kidsService.findOneById(kidId);
if (kid.parentId.toString() !== requesterParentId) {
  throw new ForbiddenException('You can only view rewards for your own kids');
}
```

### Kid 端点
```typescript
// kidToken 中的 kidId 自动匹配
if (kidId !== requesterKidId) {
  throw new ForbiddenException('You can only view your own rewards');
}
```

## 📊 数据模型

### Reward Schema

```typescript
{
  kidId: ObjectId,        // 唯一索引
  totalXP: number,        // 总 XP
  currentLevel: number,   // 当前等级
  currentStreak: number,  // 当前连续天数
  lastStreakDate: Date,   // 最后签到日期
  badges: ObjectId[],     // 已获得的徽章 ID 数组
}
```

### Badge Schema

```typescript
{
  type: BadgeType,        // 唯一索引
  name: string,
  description: string,
  icon: string,
}
```

### RewardHistory Schema

```typescript
{
  kidId: ObjectId,        // 索引
  xpEarned: number,
  source: string,         // 'quiz', 'streak', 'badge'
  sourceId: string,       // 来源 ID（可选）
  description: string,    // 描述（可选）
  createdAt: Date,       // 索引（降序）
}
```

## 🔄 集成点

### QuizService 集成

```typescript
// 在 submitQuiz() 中添加 XP 奖励
await this.rewardsService.addXP(...);
await this.rewardsService.checkQuizBadges(...);
```

### QuizModule 更新

```typescript
imports: [
  // ...
  RewardsModule,  // 新增
]
```

### AppModule 更新

```typescript
imports: [
  // ...
  RewardsModule,  // 新增
]
```

## 📝 Seed Script

### Badge Seed

运行命令: `npm run seed:badges`

创建所有 badge 定义：
- QUIZ_MASTER
- PERFECT_SCORE
- STREAK_7
- STREAK_30
- XP_1000
- XP_5000

## ✅ 测试场景

- [x] Quiz 提交后获得 XP
- [x] XP 计算正确（基础 + 分数奖励）
- [x] Streak 第一天获得 10 XP
- [x] Streak 连续天数获得额外 XP
- [x] Streak 中断后重置
- [x] Level 计算正确（每 1000 XP 一级）
- [x] Perfect Score badge 触发
- [x] Quiz Master badge 触发（10 个测验）
- [x] Streak 7 badge 触发
- [x] Streak 30 badge 触发
- [x] XP 1000 badge 触发
- [x] XP 5000 badge 触发
- [x] Kid 可以查看自己的 rewards
- [x] Parent 可以查看自己 kid 的 rewards
- [x] Parent 不能查看其他 kid 的 rewards（403）

## 📚 相关文档

- `REWARDS_TEST.md`: 详细测试指南
- `QUIZ_TEST.md`: Quiz 模块测试
- `KIDS_TEST.md`: Kids 模块测试

## ⚠️ 注意事项

1. **XP 计算**: 基础 50 XP + 分数奖励（最多 50 XP）= 最多 100 XP
2. **Streak 计算**: 第一天 10 XP，之后每天 10 + (streak * 2) XP
3. **Level 系统**: 每 1000 XP 升一级
4. **Badge 自动授予**: 满足条件时自动授予，不会重复授予
5. **Streak 重置**: 如果超过 1 天未签到，streak 重置为 1
6. **同一天重复签到**: 返回 0 XP，不更新 streak
7. **Reward 自动创建**: 首次访问时自动创建 Reward 记录

## 🔐 安全保证

1. **角色验证**: Parent 端点需要 PARENT 角色
2. **所有权验证**: 严格检查 kid 所有权
3. **数据隔离**: Kid 只能查看自己的 rewards
4. **输入验证**: 验证 kidId 格式

## 🎮 游戏化设计

### 激励机制
- **即时反馈**: Quiz 提交后立即获得 XP
- **进度可视化**: Level 和 XP 显示
- **成就系统**: Badge 收集
- **连续性奖励**: Streak 系统鼓励每日参与

### 平衡性
- **XP 上限**: Quiz 最多 100 XP，防止刷分
- **Streak 奖励递增**: 鼓励长期参与
- **Badge 难度递增**: 从简单到困难
