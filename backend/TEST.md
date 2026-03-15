# Backend 测试指南

## 安装依赖

```bash
cd backend
npm install
```

## 配置环境变量

复制 `.env.example` 到 `.env` 并修改配置：

```bash
# Windows PowerShell
Copy-Item .env.example .env

# Linux/Mac
cp .env.example .env
```

编辑 `.env` 文件：

```env
MONGODB_URI=mongodb://localhost:27017/edubridge
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
PORT=3000
NODE_ENV=development
```

## 启动 MongoDB

确保 MongoDB 服务正在运行：

```bash
# Windows (如果已安装 MongoDB 服务)
net start MongoDB

# Linux/Mac
sudo systemctl start mongod
# 或
mongod
```

## 运行开发服务器

```bash
npm run start:dev
```

服务器将在 `http://localhost:3000` 启动（或您在 `.env` 中配置的端口）。

## 测试 API 端点

### 1. 测试健康检查端点

```bash
# 使用 curl
curl http://localhost:3000/api/health

# 预期响应
{"ok":true}
```

### 2. 测试根端点

```bash
curl http://localhost:3000/api

# 预期响应
Hello from EduBridge Backend API!
```

### 3. 使用 PowerShell (Windows)

```powershell
# 健康检查
Invoke-WebRequest -Uri http://localhost:3000/api/health | Select-Object -ExpandProperty Content

# 根端点
Invoke-WebRequest -Uri http://localhost:3000/api | Select-Object -ExpandProperty Content
```

### 4. 使用浏览器

- 健康检查: `http://localhost:3000/api/health`
- 根端点: `http://localhost:3000/api`

## 测试异常过滤器

测试全局异常过滤器：

```bash
# 访问不存在的路由
curl http://localhost:3000/api/not-found

# 预期响应（JSON 格式的错误信息）
{
  "statusCode": 404,
  "timestamp": "2026-02-10T...",
  "path": "/api/not-found",
  "method": "GET",
  "message": "Cannot GET /api/not-found"
}
```

## 验证日志输出

启动服务器后，您应该看到：

```
[2026-02-10T...] [Bootstrap] 🚀 EduBridge Backend is running on: http://localhost:3000
[2026-02-10T...] [Bootstrap] 📊 Environment: development
[2026-02-10T...] [Bootstrap] 🔗 MongoDB URI: mongodb://localhost:27017/edubridge
```

## 验证 MongoDB 连接

如果 MongoDB 连接成功，您应该看到 Mongoose 的连接日志。如果连接失败，检查：

1. MongoDB 服务是否运行
2. `MONGODB_URI` 是否正确
3. MongoDB 端口是否可访问

## 完整测试脚本

### Windows PowerShell

```powershell
# 测试健康检查
Write-Host "Testing /api/health endpoint..."
$response = Invoke-WebRequest -Uri http://localhost:3000/api/health
Write-Host "Status: $($response.StatusCode)"
Write-Host "Response: $($response.Content)"

# 测试根端点
Write-Host "`nTesting /api endpoint..."
$response = Invoke-WebRequest -Uri http://localhost:3000/api
Write-Host "Status: $($response.StatusCode)"
Write-Host "Response: $($response.Content)"
```

### Linux/Mac Bash

```bash
#!/bin/bash

echo "Testing /api/health endpoint..."
curl -v http://localhost:3000/api/health
echo -e "\n"

echo "Testing /api endpoint..."
curl -v http://localhost:3000/api
echo -e "\n"
```

## 故障排除

### 端口被占用

如果端口 3000 被占用，修改 `.env` 文件中的 `PORT` 值。

### MongoDB 连接失败

1. 检查 MongoDB 是否运行: `mongosh` 或 `mongo`
2. 检查连接字符串格式
3. 如果使用远程 MongoDB，确保网络可访问

### 依赖安装问题

```bash
# 清理并重新安装
rm -rf node_modules package-lock.json
npm install
```
