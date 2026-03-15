# 快速开始指南

## 1. 安装依赖

```bash
npm install
```

## 2. 配置环境变量

创建 `.env` 文件（参考 `.env.example`）：

```env
MONGODB_URI=mongodb://localhost:27017/edubridge
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
PORT=3000
NODE_ENV=development
```

## 3. 启动 MongoDB

确保 MongoDB 服务正在运行。

## 4. 启动开发服务器

```bash
npm run start:dev
```

## 5. 测试 API

### 健康检查端点

```bash
curl http://localhost:3000/api/health
```

**预期响应:**
```json
{"ok":true}
```

### 根端点

```bash
curl http://localhost:3000/api
```

**预期响应:**
```
Hello from EduBridge Backend API!
```

## 完整测试命令

### Windows PowerShell

```powershell
# 健康检查
curl http://localhost:3000/api/health

# 根端点
curl http://localhost:3000/api

# 测试 404 错误（验证异常过滤器）
curl http://localhost:3000/api/not-found
```

### Linux/Mac

```bash
# 健康检查
curl http://localhost:3000/api/health

# 根端点
curl http://localhost:3000/api

# 测试 404 错误（验证异常过滤器）
curl http://localhost:3000/api/not-found
```

## 验证功能

✅ **环境变量配置**: 检查日志中的 MongoDB URI 和端口  
✅ **MongoDB 连接**: 检查 Mongoose 连接日志  
✅ **全局 Logger**: 查看格式化的日志输出  
✅ **异常过滤器**: 访问不存在的路由查看 JSON 错误响应  
✅ **健康检查**: `/api/health` 返回 `{"ok":true}`
