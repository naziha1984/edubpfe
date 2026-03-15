# AuthModule 完整补丁总结

## 📦 新增依赖

在 `package.json` 中添加了以下依赖：

### 运行时依赖
- `@nestjs/jwt`: JWT 模块
- `@nestjs/passport`: Passport 集成
- `passport`: 认证中间件
- `passport-jwt`: JWT Passport 策略
- `bcrypt`: 密码加密

### 开发依赖
- `@types/bcrypt`: bcrypt 类型定义
- `@types/passport-jwt`: passport-jwt 类型定义

## 📁 新增文件结构

```
backend/src/
├── users/
│   ├── schemas/
│   │   └── user.schema.ts        # User Mongoose schema
│   ├── users.module.ts           # Users 模块
│   └── users.service.ts          # Users 服务
├── auth/
│   ├── dto/
│   │   ├── register.dto.ts       # 注册 DTO
│   │   └── login.dto.ts          # 登录 DTO
│   ├── decorators/
│   │   ├── roles.decorator.ts    # @Roles() 装饰器
│   │   └── get-user.decorator.ts # @GetUser() 装饰器
│   ├── guards/
│   │   ├── jwt-auth.guard.ts     # JWT 认证守卫
│   │   └── roles.guard.ts         # 角色权限守卫
│   ├── strategies/
│   │   └── jwt.strategy.ts       # JWT Passport 策略
│   ├── auth.controller.ts        # Auth 控制器
│   ├── auth.service.ts           # Auth 服务
│   └── auth.module.ts            # Auth 模块
└── scripts/
    └── seed.ts                   # Seed script
```

## 🔧 功能实现

### 1. User Schema

- **字段**: email, password, firstName, lastName, role, isActive
- **角色枚举**: PARENT, TEACHER, ADMIN
- **默认角色**: PARENT
- **时间戳**: 自动添加 createdAt 和 updatedAt

### 2. Auth 端点

#### POST /api/auth/register
- 注册新用户（默认角色 PARENT）
- 验证 email 唯一性
- 密码使用 bcrypt 加密
- 返回 JWT token 和用户信息

#### POST /api/auth/login
- 用户登录验证
- 检查密码和账户状态
- 返回 JWT token 和用户信息

#### GET /api/auth/me
- 获取当前认证用户信息
- 需要 JWT token
- 使用 JwtAuthGuard 保护

### 3. RBAC (基于角色的访问控制)

#### RolesGuard
- 检查用户角色是否匹配要求
- 与 JwtAuthGuard 配合使用
- 权限不足时抛出 ForbiddenException

#### @Roles() 装饰器
- 用于标记需要特定角色的端点
- 支持多个角色（OR 逻辑）
- 示例: `@Roles(UserRole.ADMIN, UserRole.TEACHER)`

### 4. Seed Script

创建初始用户：
- **ADMIN**: `admin@edubridge.com` / `admin123`
- **TEACHER**: `teacher@edubridge.com` / `teacher123`

运行命令: `npm run seed`

## 🚀 使用示例

### 注册用户
```typescript
@Post('register')
async register(@Body() registerDto: RegisterDto) {
  return this.authService.register(registerDto);
}
```

### 保护端点（需要认证）
```typescript
@Get('me')
@UseGuards(JwtAuthGuard)
async getMe(@GetUser() user: any) {
  return this.authService.getProfile(user.id);
}
```

### 保护端点（需要特定角色）
```typescript
@Get('admin-only')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
adminOnly() {
  return { message: 'Admin only' };
}
```

### 多角色访问
```typescript
@Get('teacher-or-admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.TEACHER, UserRole.ADMIN)
teacherOrAdmin() {
  return { message: 'Teacher or Admin' };
}
```

## 🧪 测试命令

### 1. 运行 Seed Script
```bash
npm run seed
```

### 2. 注册用户
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "parent@example.com",
    "password": "password123",
    "firstName": "John",
    "lastName": "Doe"
  }'
```

### 3. 登录
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@edubridge.com",
    "password": "admin123"
  }'
```

### 4. 获取当前用户
```bash
curl -X GET http://localhost:3000/api/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 5. 测试 RBAC
```bash
# ADMIN 端点
curl -X GET http://localhost:3000/api/admin-only \
  -H "Authorization: Bearer ADMIN_TOKEN"

# TEACHER 或 ADMIN 端点
curl -X GET http://localhost:3000/api/teacher-or-admin \
  -H "Authorization: Bearer TEACHER_TOKEN"
```

## ✅ 验证清单

- [ ] 依赖安装成功 (`npm install`)
- [ ] Seed script 运行成功 (`npm run seed`)
- [ ] 可以注册新用户
- [ ] 可以登录用户
- [ ] 可以获取当前用户信息
- [ ] JWT token 验证正常工作
- [ ] RolesGuard 正确拒绝未授权访问
- [ ] @Roles() 装饰器正确应用权限

## 📝 配置要求

确保 `.env` 文件中包含：
```env
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
MONGODB_URI=mongodb://localhost:27017/edubridge
```

## 🔒 安全特性

1. **密码加密**: 使用 bcrypt (10 rounds)
2. **JWT 认证**: Token 有效期 24 小时
3. **角色验证**: 基于角色的访问控制
4. **账户状态**: 检查用户是否激活
5. **输入验证**: 使用 class-validator DTOs

## 📚 相关文件

- `AUTH_TEST.md`: 详细测试指南和 curl 命令
- `backend/src/auth/`: Auth 模块源代码
- `backend/src/users/`: Users 模块源代码
- `backend/src/scripts/seed.ts`: Seed script
