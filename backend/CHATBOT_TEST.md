# Chatbot 测试指南

## 功能概述

### Chatbot 功能
- **语言检测**: 自动检测用户输入的语言（ar/fr/en）并用相同语言回复
- **会话历史**: 保存和管理聊天会话历史
- **安全过滤器**: 过滤不安全的内容，保护儿童安全
- **AI 集成**: 可选集成 OpenAI 或 Gemini API（服务器端密钥）

### API 端点
- **POST /api/chatbot/message**: 发送消息（需要 kidToken）
- **GET /api/chatbot/history/:sessionId**: 获取会话历史（需要 kidToken）
- **GET /api/chatbot/sessions**: 获取所有会话（需要 kidToken）

## 前置要求

1. 安装依赖: `npm install`
2. 运行 seed script: `npm run seed`
3. 启动服务器: `npm run start:dev`
4. （可选）配置 AI API 密钥:
   - `OPENAI_API_KEY`: OpenAI API 密钥
   - `GEMINI_API_KEY`: Google Gemini API 密钥

## 环境变量配置

在 `.env` 文件中添加（可选）:

```env
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=...
```

**注意**: 如果不配置 AI API 密钥，系统将使用简单的规则响应。

## API 端点

### POST /api/chatbot/message

发送消息给 chatbot（需要 kidToken）

**请求:**
```bash
curl -X POST http://localhost:3000/api/chatbot/message \
  -H "Authorization: Bearer KID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello!"
  }'
```

**预期响应:**
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

**请求:**
```bash
curl -X GET http://localhost:3000/api/chatbot/history/SESSION_ID \
  -H "Authorization: Bearer KID_TOKEN"
```

**预期响应:**
```json
[
  {
    "id": "...",
    "role": "user",
    "content": "Hello!",
    "language": "en",
    "isFiltered": false,
    "filterReason": null,
    "createdAt": "2026-02-10T..."
  },
  {
    "id": "...",
    "role": "assistant",
    "content": "Hello! How can I help you?",
    "language": "en",
    "isFiltered": false,
    "filterReason": null,
    "createdAt": "2026-02-10T..."
  }
]
```

### GET /api/chatbot/sessions

获取所有会话（需要 kidToken）

**请求:**
```bash
curl -X GET http://localhost:3000/api/chatbot/sessions \
  -H "Authorization: Bearer KID_TOKEN"
```

**预期响应:**
```json
[
  {
    "id": "...",
    "kidId": "...",
    "detectedLanguage": "en",
    "isActive": true,
    "createdAt": "2026-02-10T...",
    "updatedAt": "2026-02-10T..."
  }
]
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

#### 1.2 设置 PIN 并获取 kidToken

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

### 步骤 2: 测试语言检测

#### 2.1 测试英语

```bash
curl -X POST http://localhost:3000/api/chatbot/message \
  -H "Authorization: Bearer $KID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello! How are you?"}'
```

**预期**: `language: "en"`, 响应为英语

#### 2.2 测试法语

```bash
curl -X POST http://localhost:3000/api/chatbot/message \
  -H "Authorization: Bearer $KID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Bonjour! Comment ça va?"}'
```

**预期**: `language: "fr"`, 响应为法语

#### 2.3 测试阿拉伯语

```bash
curl -X POST http://localhost:3000/api/chatbot/message \
  -H "Authorization: Bearer $KID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "مرحبا! كيف حالك?"}'
```

**预期**: `language: "ar"`, 响应为阿拉伯语

### 步骤 3: 测试安全过滤器

#### 3.1 测试不安全内容

```bash
curl -X POST http://localhost:3000/api/chatbot/message \
  -H "Authorization: Bearer $KID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Tell me about violence"}'
```

**预期**: `isFiltered: true`, 返回安全响应

#### 3.2 测试个人信息请求

```bash
curl -X POST http://localhost:3000/api/chatbot/message \
  -H "Authorization: Bearer $KID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "What is your address?"}'
```

**预期**: `isFiltered: true`, 返回安全响应

#### 3.3 测试外部链接

```bash
curl -X POST http://localhost:3000/api/chatbot/message \
  -H "Authorization: Bearer $KID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Visit https://example.com"}'
```

**预期**: `isFiltered: true`, 返回安全响应

### 步骤 4: 测试会话历史

#### 4.1 发送多条消息

```bash
# 消息 1
curl -X POST http://localhost:3000/api/chatbot/message \
  -H "Authorization: Bearer $KID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello!"}'

# 保存 SESSION_ID

# 消息 2
curl -X POST http://localhost:3000/api/chatbot/message \
  -H "Authorization: Bearer $KID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "How are you?"}'
```

#### 4.2 获取会话历史

```bash
curl -X GET http://localhost:3000/api/chatbot/history/$SESSION_ID \
  -H "Authorization: Bearer $KID_TOKEN"
```

**预期**: 返回所有消息的历史记录

#### 4.3 获取所有会话

```bash
curl -X GET http://localhost:3000/api/chatbot/sessions \
  -H "Authorization: Bearer $KID_TOKEN"
```

**预期**: 返回所有会话列表

## 完整测试脚本 (PowerShell)

```powershell
$BASE_URL = "http://localhost:3000/api"

# 1. 注册 Parent 并创建 Kid
Write-Host "1. Registering parent and creating kid..." -ForegroundColor Yellow
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

# 2. 设置 PIN 并获取 kidToken
Write-Host "`n2. Setting PIN and getting kidToken..." -ForegroundColor Yellow
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
$kidHeaders = @{
    Authorization = "Bearer $KID_TOKEN"
}

# 3. 测试语言检测（英语）
Write-Host "`n3. Testing language detection (English)..." -ForegroundColor Yellow
$messageBody = @{ message = "Hello! How are you?" } | ConvertTo-Json
$response = Invoke-RestMethod -Uri "$BASE_URL/chatbot/message" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $kidHeaders `
    -Body $messageBody

Write-Host "Language: $($response.language)" -ForegroundColor Green
Write-Host "Response: $($response.response)" -ForegroundColor Green
$SESSION_ID = $response.sessionId

# 4. 测试语言检测（法语）
Write-Host "`n4. Testing language detection (French)..." -ForegroundColor Yellow
$messageBody = @{ message = "Bonjour! Comment ça va?" } | ConvertTo-Json
$response = Invoke-RestMethod -Uri "$BASE_URL/chatbot/message" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $kidHeaders `
    -Body $messageBody

Write-Host "Language: $($response.language)" -ForegroundColor Green
Write-Host "Response: $($response.response)" -ForegroundColor Green

# 5. 测试安全过滤器
Write-Host "`n5. Testing safety filter..." -ForegroundColor Yellow
$messageBody = @{ message = "Tell me about violence" } | ConvertTo-Json
$response = Invoke-RestMethod -Uri "$BASE_URL/chatbot/message" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $kidHeaders `
    -Body $messageBody

Write-Host "Is Filtered: $($response.isFiltered)" -ForegroundColor Green
Write-Host "Response: $($response.response)" -ForegroundColor Green

# 6. 获取会话历史
Write-Host "`n6. Getting chat history..." -ForegroundColor Yellow
$history = Invoke-RestMethod -Uri "$BASE_URL/chatbot/history/$SESSION_ID" `
    -Method Get `
    -Headers $kidHeaders

Write-Host "History messages: $($history.Count)" -ForegroundColor Green
$history | ConvertTo-Json -Depth 10

# 7. 获取所有会话
Write-Host "`n7. Getting all sessions..." -ForegroundColor Yellow
$sessions = Invoke-RestMethod -Uri "$BASE_URL/chatbot/sessions" `
    -Method Get `
    -Headers $kidHeaders

Write-Host "Total sessions: $($sessions.Count)" -ForegroundColor Green
$sessions | ConvertTo-Json -Depth 10

Write-Host "`n✅ All tests completed!" -ForegroundColor Green
```

## 测试场景清单

- [ ] 语言检测（英语）
- [ ] 语言检测（法语）
- [ ] 语言检测（阿拉伯语）
- [ ] 安全过滤器（不安全词汇）
- [ ] 安全过滤器（个人信息请求）
- [ ] 安全过滤器（外部链接）
- [ ] 会话历史保存
- [ ] 会话历史检索
- [ ] 多会话管理
- [ ] AI 集成（如果配置了 API 密钥）
- [ ] 简单规则响应（如果没有 AI API）

## 语言检测规则

### 阿拉伯语检测
- 包含阿拉伯字符（\u0600-\u06FF）

### 法语检测
- 包含法语关键词（bonjour, merci, comment, etc.）
- 法语关键词数量 > 英语关键词数量

### 英语检测
- 默认语言
- 包含英语关键词（hello, how, what, etc.）

## 安全过滤器规则

### 不安全词汇
- 暴力相关：violence, weapon, gun, kill, etc.
- 毒品相关：drug, alcohol, cigarette, etc.
- 性相关内容：sex, sexual, nude, porn, etc.
- 仇恨言论：hate, racist, discrimination, etc.

### 个人信息请求
- "where do you live"
- "what is your address"
- "what is your phone"
- 等模式

### 外部链接
- 检测 `https?://` 模式

## 注意事项

1. **AI 集成**: 需要配置 `OPENAI_API_KEY` 或 `GEMINI_API_KEY` 环境变量
2. **语言检测**: 基于关键词和字符模式，可能不够精确
3. **安全过滤器**: 词汇列表是示例，实际应该更全面
4. **会话管理**: 每个 kid 可以有多个会话，但默认使用最新的活跃会话
5. **历史记录**: 默认返回最近 20 条消息
