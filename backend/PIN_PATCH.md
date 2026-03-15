# PIN 功能完整补丁总结

## 📦 新增文件

```
backend/src/kids/
├── dto/
│   ├── set-pin.dto.ts          # 设置 PIN DTO
│   └── verify-pin.dto.ts       # 验证 PIN DTO
├── strategies/
│   └── kid-jwt.strategy.ts     # Kid JWT 策略
├── guards/
│   └── kid-auth.guard.ts       # Kid 认证守卫
└── decorators/
    └── get-kid.decorator.ts    # @GetKid() 装饰器
```

## 🔧 更新的文件

### 1. Kid Schema

添加了以下字段：
- `hashedPin`: 加密的 PIN（bcrypt）
- `pinLockedUntil`: PIN 锁定到期时间
- `failedPinAttempts`: 失败尝试次数

### 2. KidsService

新增方法：
- `setPin(kidId, pin, parentId)`: 设置/更新 PIN（需要 ownership check）
- `verifyPin(kidId, pin)`: 验证 PIN（包含锁定逻辑）

### 3. KidsController

新增端点：
- `PUT /api/kids/:kidId/pin`: 设置 PIN（需要 parent 认证）
- `POST /api/kids/:kidId/verify-pin`: 验证 PIN 并获取 kidToken

### 4. KidsModule

添加了：
- `JwtModule`: 用于生成 kidToken
- `PassportModule`: 用于 KidJwtStrategy
- `KidJwtStrategy`: Kid token 验证策略

## 🔒 安全特性

### 1. PIN 加密
- 使用 bcrypt 加密（10 rounds）
- PIN 以哈希形式存储，不存储明文

### 2. 锁定机制
- 5 次失败尝试后锁定
- 锁定时间：10 分钟
- 锁定期间即使正确 PIN 也无法验证

### 3. 失败计数
- 每次失败增加计数
- 成功验证后重置计数和锁定时间

### 4. Ownership Check
- 设置 PIN 需要 parent 认证
- 只能设置自己 kid 的 PIN

### 5. kidToken
- JWT token，类型：KID_SESSION
- 有效期：30 分钟
- 包含 kidId 和 type 信息

## 🚀 API 端点

### PUT /api/kids/:kidId/pin

设置或更新 kid 的 PIN

**请求体:**
```json
{
  "pin": "1234"
}
```

**要求:**
- PIN 必须是 4 位数字
- 需要 parent JWT token
- 需要 ownership check

**响应:**
```json
{
  "message": "PIN set successfully"
}
```

### POST /api/kids/:kidId/verify-pin

验证 PIN 并获取 kidToken

**请求体:**
```json
{
  "pin": "1234"
}
```

**成功响应:**
```json
{
  "kidToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": "30m"
}
```

**失败响应:**
- 401: Invalid PIN
- 429: PIN locked (Too Many Requests)
- 400: PIN not set

## 🛡️ KidAuthGuard

用于保护 kid 路由，验证 kidToken：

```typescript
@Get('kid-route')
@UseGuards(KidAuthGuard)
async kidRoute(@GetKid() kid: any) {
  return { message: `Hello ${kid.firstName}!` };
}
```

### KidJwtStrategy

- 验证 token 类型为 `KID_SESSION`
- 验证 kid 存在且激活
- 返回 kid 信息（id, firstName, lastName, parentId）

## 📝 使用示例

### 1. Parent 设置 PIN

```bash
curl -X PUT http://localhost:3000/api/kids/KID_ID/pin \
  -H "Authorization: Bearer PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"pin": "1234"}'
```

### 2. Kid 验证 PIN

```bash
curl -X POST http://localhost:3000/api/kids/KID_ID/verify-pin \
  -H "Content-Type: application/json" \
  -d '{"pin": "1234"}'
```

### 3. 使用 kidToken

```bash
curl -X GET http://localhost:3000/api/kid-protected-route \
  -H "Authorization: Bearer KID_TOKEN"
```

## 🔄 锁定流程

1. **正常状态**: failedPinAttempts = 0, pinLockedUntil = null
2. **失败 1-4 次**: failedPinAttempts 递增，返回 401
3. **失败第 5 次**: 
   - failedPinAttempts = 5
   - pinLockedUntil = now + 10 minutes
   - 返回 429 Too Many Requests
4. **锁定期间**: 即使正确 PIN 也返回 429
5. **成功验证**: 重置 failedPinAttempts = 0, pinLockedUntil = null

## ✅ 测试场景

- [x] Parent 设置 PIN
- [x] Parent 更新 PIN
- [x] 正确 PIN 验证成功
- [x] 错误 PIN 验证失败
- [x] 5 次失败后锁定
- [x] 锁定期间无法验证
- [x] kidToken 生成正确
- [x] kidToken 包含正确信息
- [x] KidAuthGuard 验证 kidToken
- [x] Ownership check 工作正常

## 📚 相关文档

- `PIN_TEST.md`: 详细测试指南
- `KIDS_TEST.md`: Kids 模块测试
- `AUTH_TEST.md`: 认证模块测试

## 🔍 技术细节

### PIN 验证逻辑

```typescript
async verifyPin(kidId: string, pin: string): Promise<boolean> {
  // 1. 检查 kid 是否存在
  // 2. 检查 PIN 是否已设置
  // 3. 检查是否锁定
  // 4. 验证 PIN
  // 5. 成功：重置计数；失败：增加计数，可能锁定
}
```

### kidToken Payload

```typescript
{
  sub: kidId,
  kidId: kidId,
  type: 'KID_SESSION',
  iat: timestamp,
  exp: timestamp + 30m
}
```

### KidAuthGuard 验证流程

1. 提取 Bearer token
2. 验证 JWT 签名
3. 检查 token 类型为 KID_SESSION
4. 验证 kid 存在且激活
5. 将 kid 信息附加到 request.user

## ⚠️ 注意事项

1. **PIN 格式**: 必须是 4 位数字（0-9）
2. **锁定时间**: 固定 10 分钟，不可配置
3. **失败计数**: 存储在数据库中，不会自动过期
4. **kidToken 有效期**: 30 分钟，不可配置
5. **重置机制**: 只有成功验证才会重置失败计数
