# Parent/Enfant Flow 测试指南

## 功能概述

### 完整 Flow
1. **Login/Register**: 用户认证
2. **Kids List**: 列出所有 kids + 添加 kid
3. **Set PIN**: 为 kid 设置 PIN
4. **Verify PIN**: 验证 PIN 获取 kidToken
5. **Subjects → Lessons → Quiz**: 完整的学习流程
6. **错误处理**: 401/403 错误处理
7. **RTL 支持**: 阿拉伯语 RTL 支持

## 前置要求

1. **Backend 运行**: 确保后端服务运行在 `http://localhost:3000`
2. **安装依赖**: `flutter pub get`
3. **运行应用**: `flutter run`

## 测试流程

### 步骤 1: 注册/登录

#### 1.1 注册新用户

1. 打开应用，点击 "Get Started"
2. 填写注册表单：
   - First Name: "John"
   - Last Name: "Doe"
   - Email: "john@example.com"
   - Password: "password123"
   - Confirm Password: "password123"
3. 点击 "Create Account"
4. **预期**: 显示成功消息，导航到登录页面

#### 1.2 登录

1. 在登录页面填写：
   - Email: "john@example.com"
   - Password: "password123"
2. 点击 "Sign In"
3. **预期**: 导航到 Kids List 页面

### 步骤 2: Kids 管理

#### 2.1 查看 Kids List

1. **预期**: 显示空状态或现有 kids 列表
2. 下拉刷新列表

#### 2.2 添加 Kid

1. 点击 "Add Kid" 按钮
2. 填写表单：
   - First Name: "Alice"
   - Last Name: "Smith"
   - Grade: "5" (可选)
   - School: "Elementary School" (可选)
3. 点击 "Add Kid"
4. **预期**: 返回 Kids List，新 kid 出现在列表中

### 步骤 3: PIN 设置

#### 3.1 设置 PIN

1. 在 Kids List 中，点击 kid 旁边的锁图标
2. 输入 4 位数字 PIN: "1234"
3. 确认 PIN: "1234"
4. 点击 "Set PIN"
5. **预期**: 显示成功消息，返回 Kids List

### 步骤 4: PIN 验证

#### 4.1 验证 PIN

1. 在 Kids List 中，点击 kid 卡片
2. 输入 PIN: "1234"
3. **预期**: 自动验证（输入 4 位后）或点击 "Verify"
4. **预期**: 导航到 Subjects 页面

### 步骤 5: Quiz 流程

#### 5.1 选择 Subject

1. 在 Subjects 页面，查看所有 subjects
2. 点击一个 subject
3. **预期**: 导航到 Lessons 页面

#### 5.2 选择 Lesson

1. 在 Lessons 页面，查看该 subject 的所有 lessons
2. 点击一个 lesson
3. **预期**: 导航到 Quiz 页面

#### 5.3 完成 Quiz

1. 在 Quiz 页面，回答所有问题
2. 点击 "Submit Quiz"
3. **预期**: 导航到 Quiz Result 页面

#### 5.4 查看结果

1. 在 Quiz Result 页面，查看：
   - Score (分数/总分)
   - Percentage (百分比)
   - XP Earned (XP 奖励)
2. 点击 "Back to Lessons"
3. **预期**: 返回 Kids List

## 错误处理测试

### 测试 1: 401 Unauthorized

1. **场景**: Token 过期或无效
2. **操作**: 尝试访问需要认证的端点
3. **预期**: 显示 "Unauthorized. Please login again." 错误消息

### 测试 2: 403 Forbidden

1. **场景**: 权限不足
2. **操作**: 尝试访问需要特定角色的端点
3. **预期**: 显示 "Access denied. You don't have permission." 错误消息

### 测试 3: 网络错误

1. **场景**: 后端服务未运行
2. **操作**: 尝试任何 API 调用
3. **预期**: 显示通用错误消息

## RTL 测试

### 测试 1: 阿拉伯语 RTL

1. 在 Kids List 页面，选择语言为 "AR"
2. **预期**: 
   - 文本方向变为 RTL
   - 对齐方式自动调整
   - 图标位置调整

### 测试 2: 法语/英语 LTR

1. 选择语言为 "FR" 或 "EN"
2. **预期**: 
   - 文本方向为 LTR
   - 正常对齐

## 完整测试脚本

### 手动测试流程

1. ✅ 注册新用户
2. ✅ 登录
3. ✅ 添加 kid
4. ✅ 设置 PIN
5. ✅ 验证 PIN
6. ✅ 查看 subjects
7. ✅ 选择 lesson
8. ✅ 完成 quiz
9. ✅ 查看结果
10. ✅ 测试错误处理
11. ✅ 测试 RTL 支持

## API 端点测试

### 使用 curl 测试后端

#### 1. 注册
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User"
  }'
```

#### 2. 登录
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

#### 3. 获取 Kids
```bash
curl -X GET http://localhost:3000/api/kids \
  -H "Authorization: Bearer TOKEN"
```

#### 4. 添加 Kid
```bash
curl -X POST http://localhost:3000/api/kids \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Alice",
    "lastName": "Smith"
  }'
```

#### 5. 设置 PIN
```bash
curl -X PUT http://localhost:3000/api/kids/KID_ID/pin \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"pin": "1234"}'
```

#### 6. 验证 PIN
```bash
curl -X POST http://localhost:3000/api/kids/KID_ID/verify-pin \
  -H "Content-Type: application/json" \
  -d '{"pin": "1234"}'
```

#### 7. 获取 Subjects
```bash
curl -X GET http://localhost:3000/api/subjects
```

#### 8. 获取 Lessons
```bash
curl -X GET http://localhost:3000/api/subjects/SUBJECT_ID/lessons
```

#### 9. 创建 Quiz Session
```bash
curl -X POST http://localhost:3000/api/quiz/sessions \
  -H "Authorization: Bearer KID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "kidId": "KID_ID",
    "lessonId": "LESSON_ID"
  }'
```

#### 10. 提交 Quiz
```bash
curl -X POST http://localhost:3000/api/quiz/submit \
  -H "Authorization: Bearer KID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "SESSION_ID",
    "answers": [
      {"questionIndex": 0, "selectedAnswer": 1}
    ]
  }'
```

## 测试场景清单

### 认证流程
- [ ] 注册成功
- [ ] 注册失败（重复邮箱）
- [ ] 登录成功
- [ ] 登录失败（错误密码）
- [ ] 401 错误处理
- [ ] 403 错误处理

### Kids 管理
- [ ] 列出 kids（空列表）
- [ ] 列出 kids（有数据）
- [ ] 添加 kid 成功
- [ ] 添加 kid 失败（验证错误）
- [ ] 下拉刷新

### PIN 流程
- [ ] 设置 PIN 成功
- [ ] 设置 PIN 失败（验证错误）
- [ ] 验证 PIN 成功
- [ ] 验证 PIN 失败（错误 PIN）
- [ ] PIN 锁定（5 次失败）

### Quiz 流程
- [ ] 列出 subjects
- [ ] 列出 lessons
- [ ] 创建 quiz session
- [ ] 显示问题
- [ ] 提交答案
- [ ] 显示结果
- [ ] XP 奖励显示

### RTL 支持
- [ ] 阿拉伯语 RTL
- [ ] 法语 LTR
- [ ] 英语 LTR
- [ ] 文本方向切换

## 注意事项

1. **API URL**: 确保 `baseUrl` 正确（默认: `http://localhost:3000/api`）
2. **Token 管理**: Token 存储在内存中，应用重启后需要重新登录
3. **kidToken**: 仅在验证 PIN 后可用
4. **错误处理**: 所有错误都会显示 SnackBar
5. **RTL 支持**: 需要手动选择语言

## 调试技巧

### 查看 API 调用
- 在 `ApiService` 中添加日志
- 使用 Flutter DevTools 网络面板

### 查看状态
- 使用 Provider 的 `Consumer` 或 `Selector`
- 在 DevTools 中查看 Provider 状态

### 测试错误场景
- 修改 `baseUrl` 为无效 URL
- 使用无效 token
- 使用无效 kidToken
