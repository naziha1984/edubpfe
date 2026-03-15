# Backend 初始化补丁总结

## 📦 新增依赖

在 `package.json` 中添加了以下依赖：

- `@nestjs/config`: 环境变量配置管理
- `@nestjs/mongoose`: MongoDB/Mongoose 集成
- `mongoose`: MongoDB ODM
- `class-validator`: 数据验证
- `class-transformer`: 数据转换

## 📁 新增文件结构

```
backend/
├── .env.example              # 环境变量示例文件
├── src/
│   ├── config/
│   │   ├── config.module.ts  # 配置模块（全局）
│   │   └── config.service.ts # 配置服务
│   ├── database/
│   │   └── database.module.ts # MongoDB 连接模块
│   ├── common/
│   │   ├── filters/
│   │   │   └── http-exception.filter.ts # 全局异常过滤器
│   │   └── logger/
│   │       └── logger.service.ts        # 全局日志服务
│   ├── main.ts               # 更新：集成所有功能
│   ├── app.module.ts         # 更新：导入新模块
│   └── app.controller.ts     # 更新：/api/health 端点
├── TEST.md                   # 详细测试指南
└── QUICK_START.md            # 快速开始指南
```

## 🔧 配置更改

### 环境变量 (.env)

```env
MONGODB_URI=mongodb://localhost:27017/edubridge
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
PORT=3000
NODE_ENV=development
```

### 主要功能

1. **环境变量配置**: 通过 `ConfigService` 统一管理
2. **MongoDB 连接**: 使用 Mongoose 异步连接
3. **全局 Logger**: 自定义日志服务，带时间戳和上下文
4. **全局异常过滤器**: 统一错误响应格式
5. **全局前缀**: 所有路由添加 `/api` 前缀
6. **健康检查端点**: `/api/health` 返回 `{"ok":true}`

## 🚀 运行命令

### 安装依赖
```bash
cd backend
npm install
```

### 开发模式
```bash
npm run start:dev
```

### 生产模式
```bash
npm run build
npm run start:prod
```

## 🧪 测试命令

### 健康检查
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

### 测试异常过滤器（404）
```bash
curl http://localhost:3000/api/not-found
```

**预期响应:**
```json
{
  "statusCode": 404,
  "timestamp": "2026-02-10T...",
  "path": "/api/not-found",
  "method": "GET",
  "message": "Cannot GET /api/not-found"
}
```

### Windows PowerShell 测试

```powershell
# 健康检查
Invoke-WebRequest -Uri http://localhost:3000/api/health | Select-Object -ExpandProperty Content

# 根端点
Invoke-WebRequest -Uri http://localhost:3000/api | Select-Object -ExpandProperty Content
```

## ✅ 验证清单

- [ ] 依赖安装成功 (`npm install`)
- [ ] `.env` 文件已创建并配置
- [ ] MongoDB 服务正在运行
- [ ] 服务器成功启动（端口 3000）
- [ ] `/api/health` 返回 `{"ok":true}`
- [ ] 日志输出格式正确（带时间戳和上下文）
- [ ] 异常过滤器正常工作（404 返回 JSON 格式错误）
- [ ] MongoDB 连接成功（检查日志）

## 📝 注意事项

1. **MongoDB 连接**: 确保 MongoDB 服务在启动前运行
2. **环境变量**: `.env` 文件不会被提交到 Git（已在 `.gitignore` 中）
3. **端口配置**: 默认端口 3000，可通过 `.env` 中的 `PORT` 修改
4. **JWT Secret**: 生产环境必须更改默认的 JWT_SECRET

## 🔍 故障排除

### MongoDB 连接失败
- 检查 MongoDB 服务是否运行
- 验证 `MONGODB_URI` 是否正确
- 检查网络连接和防火墙设置

### 端口被占用
- 修改 `.env` 中的 `PORT` 值
- 或停止占用端口的其他服务

### 依赖安装问题
```bash
rm -rf node_modules package-lock.json
npm install
```
