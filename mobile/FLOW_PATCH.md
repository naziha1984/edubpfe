# Parent/Enfant Flow 完整补丁总结

## 📦 新增文件

```
mobile/lib/
├── services/
│   └── api_service.dart          # API 服务层
├── providers/
│   ├── auth_provider.dart       # 认证 Provider
│   ├── kids_provider.dart        # Kids Provider
│   └── quiz_provider.dart        # Quiz Provider
├── utils/
│   ├── error_handler.dart        # 错误处理工具
│   └── rtl_support.dart          # RTL 支持工具
└── pages/
    ├── kids_list_page.dart       # Kids 列表页面
    ├── add_kid_page.dart         # 添加 Kid 页面
    ├── set_pin_page.dart         # 设置 PIN 页面
    ├── verify_pin_page.dart      # 验证 PIN 页面
    ├── subjects_page.dart        # Subjects 列表页面
    ├── lessons_page.dart         # Lessons 列表页面
    ├── quiz_page.dart            # Quiz 页面
    └── quiz_result_page.dart     # Quiz 结果页面
```

## 🔄 完整 Flow

### 1. 认证流程

#### Login
- **页面**: `LoginPage`
- **API**: `POST /api/auth/login`
- **功能**: 
  - 表单验证
  - API 调用
  - Token 存储
  - 错误处理（401/403）
  - 导航到 Kids List

#### Register
- **页面**: `RegisterPage`
- **API**: `POST /api/auth/register`
- **功能**:
  - 完整注册表单
  - 密码确认验证
  - API 调用
  - Token 存储
  - 错误处理
  - 导航到 Login

### 2. Kids 管理流程

#### Kids List
- **页面**: `KidsListPage`
- **API**: `GET /api/kids`
- **功能**:
  - 显示所有 kids
  - 添加 kid 按钮
  - 设置 PIN 按钮
  - 点击 kid 进入 PIN 验证
  - RTL 支持
  - 下拉刷新

#### Add Kid
- **页面**: `AddKidPage`
- **API**: `POST /api/kids`
- **功能**:
  - 表单验证
  - API 调用
  - 错误处理
  - 返回并刷新列表

### 3. PIN 流程

#### Set PIN
- **页面**: `SetPinPage`
- **API**: `PUT /api/kids/:kidId/pin`
- **功能**:
  - 4 位数字 PIN
  - PIN 确认
  - API 调用
  - 错误处理

#### Verify PIN
- **页面**: `VerifyPinPage`
- **API**: `POST /api/kids/:kidId/verify-pin`
- **功能**:
  - PIN 输入（4 位）
  - 自动提交（输入 4 位后）
  - kidToken 获取
  - 导航到 Subjects

### 4. Quiz 流程

#### Subjects
- **页面**: `SubjectsPage`
- **API**: `GET /api/subjects`
- **功能**:
  - 显示所有 subjects
  - 点击进入 Lessons
  - 使用 kidToken

#### Lessons
- **页面**: `LessonsPage`
- **API**: `GET /api/subjects/:id/lessons`
- **功能**:
  - 显示 subject 的 lessons
  - 点击进入 Quiz
  - 使用 kidToken

#### Quiz
- **页面**: `QuizPage`
- **API**: 
  - `POST /api/quiz/sessions` (创建会话)
  - `POST /api/quiz/submit` (提交答案)
- **功能**:
  - 创建 quiz session
  - 显示问题
  - 收集答案
  - 提交 quiz
  - 使用 kidToken

#### Quiz Result
- **页面**: `QuizResultPage`
- **功能**:
  - 显示分数
  - 显示百分比
  - 显示 XP 奖励
  - 返回按钮

## 🔒 错误处理

### 401 Unauthorized
- **处理**: 显示错误消息
- **行为**: 提示重新登录
- **实现**: `ErrorHandler.showError()`

### 403 Forbidden
- **处理**: 显示错误消息
- **行为**: 提示权限不足
- **实现**: `ErrorHandler.showError()`

### 通用错误处理
- **包装器**: `ErrorHandler.handleApiCall()`
- **功能**: 统一错误处理
- **返回**: null 表示错误，否则返回结果

## 🌐 RTL 支持

### 语言检测
- **支持语言**: ar (阿拉伯语), fr (法语), en (英语)
- **实现**: `RTLSupport` 工具类

### RTL 功能
- **TextDirection**: 自动设置文本方向
- **Alignment**: 自动调整对齐
- **CrossAxisAlignment**: 自动调整交叉轴对齐
- **MainAxisAlignment**: 自动调整主轴对齐

### 使用示例
```dart
Directionality(
  textDirection: RTLSupport.getTextDirection(language),
  child: Widget(...),
)
```

## 📱 页面导航流程

```
Welcome
  ├── Register ──> Login
  └── Login ──> Kids List
       ├── Add Kid ──> (返回) Kids List
       ├── Set PIN ──> (返回) Kids List
       └── (点击 Kid) ──> Verify PIN
            └── Subjects
                 └── Lessons
                      └── Quiz
                           └── Quiz Result ──> (返回) Kids List
```

## 🔧 Provider 架构

### AuthProvider
- **状态**: user, isLoading, isAuthenticated
- **方法**: register, login, logout, loadProfile

### KidsProvider
- **状态**: kids, isLoading
- **方法**: loadKids, addKid, setPin, verifyPin

### QuizProvider
- **状态**: subjects, lessons, currentSession, quizResult, isLoading
- **方法**: loadSubjects, loadLessons, createSession, submitQuiz

## 🚀 API 集成

### API Service
- **基础 URL**: `http://localhost:3000/api`
- **Token 管理**: 自动添加到请求头
- **kidToken 支持**: 用于 kid 相关 API

### 端点映射
- `POST /api/auth/register` → `ApiService.register()`
- `POST /api/auth/login` → `ApiService.login()`
- `GET /api/kids` → `ApiService.getKids()`
- `POST /api/kids` → `ApiService.addKid()`
- `PUT /api/kids/:kidId/pin` → `ApiService.setPin()`
- `POST /api/kids/:kidId/verify-pin` → `ApiService.verifyPin()`
- `GET /api/subjects` → `ApiService.getSubjects()`
- `GET /api/subjects/:id/lessons` → `ApiService.getLessons()`
- `POST /api/quiz/sessions` → `ApiService.createQuizSession()`
- `POST /api/quiz/submit` → `ApiService.submitQuiz()`

## ✅ 测试场景

### 认证流程
- [x] 注册新用户
- [x] 登录现有用户
- [x] 401 错误处理
- [x] 403 错误处理
- [x] 表单验证

### Kids 管理
- [x] 列出所有 kids
- [x] 添加新 kid
- [x] 表单验证
- [x] 错误处理

### PIN 流程
- [x] 设置 PIN（4 位数字）
- [x] PIN 确认验证
- [x] 验证 PIN
- [x] kidToken 获取
- [x] 错误处理

### Quiz 流程
- [x] 列出 subjects
- [x] 列出 lessons
- [x] 创建 quiz session
- [x] 显示问题
- [x] 提交答案
- [x] 显示结果
- [x] XP 奖励显示

### RTL 支持
- [x] 阿拉伯语 RTL
- [x] 法语/英语 LTR
- [x] 自动文本方向
- [x] 自动对齐

## 📝 依赖

### 新增依赖
```yaml
provider: ^6.1.1  # 状态管理
intl: ^0.19.0     # 国际化支持
```

## 🔐 安全特性

1. **Token 管理**: 自动添加到请求头
2. **kidToken 隔离**: 仅用于 kid 相关 API
3. **错误处理**: 统一处理 401/403
4. **表单验证**: 客户端验证

## 📚 相关文档

- `DESIGN_SYSTEM_PATCH.md`: 设计系统文档
- Backend API 文档: 参考 backend 目录

## ⚠️ 注意事项

1. **API URL**: 需要根据实际环境修改 `baseUrl`
2. **错误处理**: 所有 API 调用都通过 `ErrorHandler.handleApiCall()`
3. **Token 持久化**: 当前在内存中，建议添加持久化存储
4. **RTL 支持**: 需要根据用户选择或系统设置应用
5. **Quiz 问题**: 当前使用模拟数据，需要从 API 获取

## 🎯 下一步改进

1. **Token 持久化**: 使用 SharedPreferences 或 secure storage
2. **离线支持**: 添加本地缓存
3. **Quiz 问题**: 从 API 获取真实问题
4. **多语言**: 完整的国际化支持
5. **动画**: 页面转场动画
