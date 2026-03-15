# Chatbot 完整补丁总结

## 📦 新增文件

```
backend/src/chatbot/
├── schemas/
│   ├── chat-session.schema.ts     # ChatSession schema
│   └── chat-message.schema.ts      # ChatMessage schema
├── services/
│   ├── language-detector.service.ts  # 语言检测服务
│   └── safety-filter.service.ts      # 安全过滤器服务
├── chatbot.service.ts               # Chatbot 服务（AI 集成）
├── chatbot.controller.ts           # Chatbot 控制器
└── chatbot.module.ts               # Chatbot 模块
```

## 🔧 功能实现

### 1. 语言检测

#### 支持的语言
- **ar**: 阿拉伯语
- **fr**: 法语
- **en**: 英语（默认）

#### 检测逻辑
1. **阿拉伯语检测**: 检查是否包含阿拉伯字符（\u0600-\u06FF）
2. **法语检测**: 检查法语关键词数量
3. **英语检测**: 默认语言或英语关键词数量多

**实现位置**: `LanguageDetectorService.detectLanguage()`

```typescript
detectLanguage(text: string): 'ar' | 'fr' | 'en' {
  // 检测阿拉伯语
  if (arabicPattern.test(text)) {
    return 'ar';
  }
  
  // 检测法语/英语关键词
  // ...
}
```

### 2. 安全过滤器

#### 过滤规则
1. **不安全词汇**: 暴力、毒品、性内容、仇恨言论
2. **个人信息请求**: 地址、电话、邮箱等
3. **外部链接**: URL 模式检测

**实现位置**: `SafetyFilterService.checkSafety()`

```typescript
checkSafety(message: string, language: 'ar' | 'fr' | 'en'): {
  isSafe: boolean;
  reason?: string;
}
```

#### 安全响应
当消息被过滤时，返回安全响应：
- **英语**: "I'm sorry, but I can't respond to that. Let's talk about something else!"
- **法语**: "Je suis désolé, mais je ne peux pas répondre à cela. Parlons d'autre chose !"
- **阿拉伯语**: "أنا آسف، لكن لا يمكنني الرد على ذلك. دعنا نتحدث عن شيء آخر!"

### 3. 会话历史

#### ChatSession Schema
- `kidId`: Kid ID
- `detectedLanguage`: 检测到的语言
- `isActive`: 是否活跃
- `timestamps`: 自动添加 createdAt 和 updatedAt

#### ChatMessage Schema
- `sessionId`: 会话 ID
- `role`: 消息角色（user, assistant, system）
- `content`: 消息内容
- `language`: 消息语言
- `isFiltered`: 是否被过滤
- `filterReason`: 过滤原因
- `timestamps`: 自动添加 createdAt

### 4. AI 集成

#### OpenAI 集成
- **API**: `https://api.openai.com/v1/chat/completions`
- **模型**: `gpt-3.5-turbo`
- **环境变量**: `OPENAI_API_KEY`

#### Gemini 集成
- **API**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent`
- **环境变量**: `GEMINI_API_KEY`

#### 简单规则响应
如果没有配置 AI API 密钥，使用简单的规则响应：
- 问候语检测
- 问题检测
- 默认响应

## 🚀 API 端点

### POST /api/chatbot/message

发送消息给 chatbot（需要 kidToken）

**认证**: Kid JWT (kidToken)
**请求体:**
```json
{
  "message": "Hello!"
}
```

**响应:**
```json
{
  "response": "Hello! How can I help you?",
  "sessionId": "...",
  "language": "en",
  "isFiltered": false
}
```

### GET /api/chatbot/history/:sessionId

获取会话历史（需要 kidToken）

**认证**: Kid JWT (kidToken)
**响应:**
```json
[
  {
    "id": "...",
    "role": "user",
    "content": "Hello!",
    "language": "en",
    "isFiltered": false,
    "filterReason": null,
    "createdAt": "..."
  }
]
```

### GET /api/chatbot/sessions

获取所有会话（需要 kidToken）

**认证**: Kid JWT (kidToken)
**响应:**
```json
[
  {
    "id": "...",
    "kidId": "...",
    "detectedLanguage": "en",
    "isActive": true,
    "createdAt": "...",
    "updatedAt": "..."
  }
]
```

## 🔒 安全特性

1. **Kid Token 验证**: 所有端点需要 kidToken
2. **安全过滤器**: 自动过滤不安全内容
3. **会话隔离**: 每个 kid 只能访问自己的会话
4. **API 密钥保护**: AI API 密钥存储在服务器端

## 📊 数据模型

### ChatSession
```typescript
{
  kidId: ObjectId,
  detectedLanguage: string,  // 'ar', 'fr', 'en'
  isActive: boolean,
  createdAt: Date,
  updatedAt: Date,
}
```

### ChatMessage
```typescript
{
  sessionId: ObjectId,
  role: MessageRole,  // 'user', 'assistant', 'system'
  content: string,
  language: string,   // 'ar', 'fr', 'en'
  isFiltered: boolean,
  filterReason: string,
  createdAt: Date,
}
```

## 🔄 工作流程

### 发送消息流程

1. **接收消息**: 从 kidToken 获取 kidId
2. **获取/创建会话**: 获取或创建活跃会话
3. **语言检测**: 检测消息语言
4. **安全过滤**: 检查消息安全性
5. **生成响应**: 
   - 如果被过滤：返回安全响应
   - 如果配置了 AI：调用 AI API
   - 否则：使用简单规则响应
6. **保存消息**: 保存用户消息和 AI 响应

### AI 响应生成

1. **获取历史**: 获取会话历史（最多 20 条）
2. **构建提示**: 添加系统提示和历史消息
3. **调用 API**: 调用 OpenAI 或 Gemini API
4. **错误处理**: 如果 API 失败，回退到简单规则响应

## 📝 环境变量

### 可选配置

```env
# OpenAI API 密钥（可选）
OPENAI_API_KEY=sk-...

# Gemini API 密钥（可选）
GEMINI_API_KEY=...
```

**注意**: 如果不配置 AI API 密钥，系统将使用简单的规则响应。

## ✅ 测试场景

- [x] 语言检测（英语）
- [x] 语言检测（法语）
- [x] 语言检测（阿拉伯语）
- [x] 安全过滤器（不安全词汇）
- [x] 安全过滤器（个人信息请求）
- [x] 安全过滤器（外部链接）
- [x] 会话历史保存
- [x] 会话历史检索
- [x] 多会话管理
- [x] AI 集成（如果配置了 API 密钥）
- [x] 简单规则响应（如果没有 AI API）

## 📚 相关文档

- `CHATBOT_TEST.md`: 详细测试指南
- `KIDS_TEST.md`: Kids 模块测试

## ⚠️ 注意事项

1. **语言检测**: 基于关键词和字符模式，可能不够精确
2. **安全过滤器**: 词汇列表是示例，实际应该更全面
3. **AI 集成**: 需要配置 API 密钥才能使用
4. **会话管理**: 每个 kid 可以有多个会话，但默认使用最新的活跃会话
5. **历史记录**: 默认返回最近 20 条消息
6. **API 密钥**: 存储在服务器端，不会暴露给客户端

## 🔐 安全保证

1. **Kid Token 验证**: 所有端点需要 kidToken
2. **安全过滤器**: 自动过滤不安全内容
3. **会话隔离**: 每个 kid 只能访问自己的会话
4. **API 密钥保护**: AI API 密钥存储在服务器端环境变量中

## 🎯 语言支持

### 英语 (en)
- 默认语言
- 支持问候、问题、默认响应

### 法语 (fr)
- 关键词检测
- 法语响应

### 阿拉伯语 (ar)
- 字符检测
- 阿拉伯语响应

## 🔧 扩展性

### 添加新语言

1. 在 `LanguageDetectorService` 中添加检测逻辑
2. 在 `SafetyFilterService` 中添加安全响应
3. 在 `ChatbotService` 中添加简单规则响应

### 改进语言检测

可以集成专业的语言检测库，如：
- `franc`: 语言检测库
- `language-detector`: 语言检测库

### 改进安全过滤器

可以集成专业的内容过滤服务，如：
- Google Perspective API
- Azure Content Moderator
- AWS Comprehend
