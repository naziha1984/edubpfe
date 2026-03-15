# AuthModule 快速参考

## 🚀 快速开始

### 1. 安装依赖
```bash
npm install
```

### 2. 运行 Seed Script
```bash
npm run seed
```

这将创建：
- **ADMIN**: `admin@edubridge.com` / `admin123`
- **TEACHER**: `teacher@edubridge.com` / `teacher123`

### 3. 启动服务器
```bash
npm run start:dev
```

## 📋 API 端点

### POST /api/auth/register
注册新用户（默认角色 PARENT）

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

### POST /api/auth/login
用户登录

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@edubridge.com",
    "password": "admin123"
  }'
```

### GET /api/auth/me
获取当前用户信息（需要 JWT token）

```bash
curl -X GET http://localhost:3000/api/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🔐 RBAC 使用

### 保护端点（需要认证）
```typescript
@Get('protected')
@UseGuards(JwtAuthGuard)
async protected(@GetUser() user: any) {
  return { message: `Hello ${user.email}` };
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

## 🧪 快速测试

### 使用测试脚本

**Linux/Mac:**
```bash
chmod +x test-auth.sh
./test-auth.sh
```

**Windows PowerShell:**
```powershell
.\test-auth.ps1
```

### 手动测试流程

1. **注册用户**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"pass123","firstName":"Test","lastName":"User"}'
```

2. **保存 token** (从响应中复制 `access_token`)

3. **获取用户信息**
```bash
curl -X GET http://localhost:3000/api/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

4. **登录 ADMIN**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@edubridge.com","password":"admin123"}'
```

5. **测试 ADMIN 端点**
```bash
curl -X GET http://localhost:3000/api/admin-only \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

## 📝 用户角色

- **PARENT**: 默认角色，注册时自动分配
- **TEACHER**: 通过 seed script 创建
- **ADMIN**: 通过 seed script 创建

## 🔑 装饰器

- `@GetUser()`: 获取当前认证用户
- `@Roles(...roles)`: 指定需要的角色

## 🛡️ 守卫

- `JwtAuthGuard`: JWT 认证守卫
- `RolesGuard`: 角色权限守卫（需与 JwtAuthGuard 一起使用）

## 📚 详细文档

- `AUTH_TEST.md`: 完整测试指南
- `AUTH_PATCH.md`: 补丁总结
- `test-auth.sh`: Linux/Mac 测试脚本
- `test-auth.ps1`: Windows PowerShell 测试脚本
