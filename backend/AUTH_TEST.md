# AuthModule 测试指南

## 前置要求

1. 安装依赖: `npm install`
2. 确保 MongoDB 正在运行
3. 运行 seed script 创建初始用户

## 运行 Seed Script

```bash
npm run seed
```

这将创建以下用户：
- **ADMIN**: `admin@edubridge.com` / `admin123`
- **TEACHER**: `teacher@edubridge.com` / `teacher123`

## API 端点

所有端点都在 `/api` 前缀下。

### 1. POST /api/auth/register

注册新用户（默认角色为 PARENT）

**请求:**
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

**预期响应:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "...",
    "email": "parent@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "PARENT"
  }
}
```

### 2. POST /api/auth/login

用户登录

**请求:**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@edubridge.com",
    "password": "admin123"
  }'
```

**预期响应:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "...",
    "email": "admin@edubridge.com",
    "firstName": "Admin",
    "lastName": "User",
    "role": "ADMIN"
  }
  }
}
```

### 3. GET /api/auth/me

获取当前用户信息（需要 JWT token）

**请求:**
```bash
curl -X GET http://localhost:3000/api/auth/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**预期响应:**
```json
{
  "id": "...",
  "email": "admin@edubridge.com",
  "firstName": "Admin",
  "lastName": "User",
  "role": "ADMIN",
  "isActive": true
}
```

## RBAC 测试端点

### 4. GET /api/admin-only

仅 ADMIN 可访问

**请求 (ADMIN):**
```bash
curl -X GET http://localhost:3000/api/admin-only \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

**预期响应:**
```json
{
  "message": "This is an admin-only endpoint"
}
```

**请求 (非 ADMIN):**
```bash
curl -X GET http://localhost:3000/api/admin-only \
  -H "Authorization: Bearer PARENT_TOKEN"
```

**预期响应 (403 Forbidden):**
```json
{
  "statusCode": 403,
  "message": "Forbidden resource"
}
```

### 5. GET /api/teacher-or-admin

TEACHER 或 ADMIN 可访问

**请求:**
```bash
curl -X GET http://localhost:3000/api/teacher-or-admin \
  -H "Authorization: Bearer TEACHER_OR_ADMIN_TOKEN"
```

## 完整测试流程

### Windows PowerShell

```powershell
# 1. 注册新用户
$registerBody = @{
    email = "parent@example.com"
    password = "password123"
    firstName = "John"
    lastName = "Doe"
} | ConvertTo-Json

$registerResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/register" `
    -Method Post `
    -ContentType "application/json" `
    -Body $registerBody

$token = $registerResponse.access_token
Write-Host "Token: $token"

# 2. 获取当前用户信息
$headers = @{
    Authorization = "Bearer $token"
}

$meResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/me" `
    -Method Get `
    -Headers $headers

Write-Host "User Info:"
$meResponse | ConvertTo-Json

# 3. 登录 ADMIN
$loginBody = @{
    email = "admin@edubridge.com"
    password = "admin123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" `
    -Method Post `
    -ContentType "application/json" `
    -Body $loginBody

$adminToken = $loginResponse.access_token

# 4. 测试 ADMIN 端点
$adminHeaders = @{
    Authorization = "Bearer $adminToken"
}

$adminResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/admin-only" `
    -Method Get `
    -Headers $adminHeaders

Write-Host "Admin Endpoint:"
$adminResponse | ConvertTo-Json
```

### Linux/Mac Bash

```bash
#!/bin/bash

BASE_URL="http://localhost:3000/api"

# 1. 注册新用户
echo "1. Registering new user..."
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "parent@example.com",
    "password": "password123",
    "firstName": "John",
    "lastName": "Doe"
  }')

TOKEN=$(echo $REGISTER_RESPONSE | jq -r '.access_token')
echo "Token: $TOKEN"
echo ""

# 2. 获取当前用户信息
echo "2. Getting current user info..."
curl -s -X GET "$BASE_URL/auth/me" \
  -H "Authorization: Bearer $TOKEN" | jq
echo ""

# 3. 登录 ADMIN
echo "3. Logging in as ADMIN..."
ADMIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@edubridge.com",
    "password": "admin123"
  }')

ADMIN_TOKEN=$(echo $ADMIN_RESPONSE | jq -r '.access_token')
echo "Admin Token: $ADMIN_TOKEN"
echo ""

# 4. 测试 ADMIN 端点
echo "4. Testing admin-only endpoint..."
curl -s -X GET "$BASE_URL/admin-only" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq
echo ""

# 5. 登录 TEACHER
echo "5. Logging in as TEACHER..."
TEACHER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teacher@edubridge.com",
    "password": "teacher123"
  }')

TEACHER_TOKEN=$(echo $TEACHER_RESPONSE | jq -r '.access_token')

# 6. 测试 TEACHER 或 ADMIN 端点
echo "6. Testing teacher-or-admin endpoint..."
curl -s -X GET "$BASE_URL/teacher-or-admin" \
  -H "Authorization: Bearer $TEACHER_TOKEN" | jq
```

## 测试用例

### 测试 1: 注册新用户
- ✅ 成功注册 PARENT 用户
- ✅ 返回 access_token
- ✅ 验证 email 唯一性（重复注册应失败）

### 测试 2: 用户登录
- ✅ 使用正确凭据登录成功
- ✅ 使用错误密码登录失败
- ✅ 使用不存在的 email 登录失败

### 测试 3: 获取当前用户
- ✅ 使用有效 token 获取用户信息
- ✅ 使用无效 token 返回 401

### 测试 4: RBAC 权限控制
- ✅ ADMIN 可以访问 `/api/admin-only`
- ✅ PARENT 不能访问 `/api/admin-only` (403)
- ✅ TEACHER 和 ADMIN 可以访问 `/api/teacher-or-admin`
- ✅ PARENT 不能访问 `/api/teacher-or-admin` (403)

## 错误处理测试

### 无效 token
```bash
curl -X GET http://localhost:3000/api/auth/me \
  -H "Authorization: Bearer invalid_token"
```
**预期:** 401 Unauthorized

### 缺少 token
```bash
curl -X GET http://localhost:3000/api/auth/me
```
**预期:** 401 Unauthorized

### 权限不足
```bash
# 使用 PARENT token 访问 ADMIN 端点
curl -X GET http://localhost:3000/api/admin-only \
  -H "Authorization: Bearer PARENT_TOKEN"
```
**预期:** 403 Forbidden

## 用户角色

- **PARENT**: 默认角色，注册时自动分配
- **TEACHER**: 通过 seed script 创建
- **ADMIN**: 通过 seed script 创建

## 注意事项

1. JWT token 有效期为 24 小时
2. 密码使用 bcrypt 加密存储
3. 所有密码验证都使用 bcrypt.compare
4. 用户必须处于激活状态才能登录
5. RolesGuard 需要与 JwtAuthGuard 一起使用
