# 测试指南

## Backend 测试步骤

### 1. 安装依赖
```bash
cd backend
npm install
```

### 2. 启动开发服务器
```bash
npm run start:dev
```

### 3. 验证 API 端点

#### 测试根端点
```bash
curl http://localhost:3000
```
**预期响应**: `Hello from EduBridge Backend API!`

#### 测试健康检查端点
```bash
curl http://localhost:3000/health
```
**预期响应**:
```json
{
  "status": "ok",
  "service": "EduBridge Backend",
  "timestamp": "2026-02-10T..."
}
```

### 4. 运行单元测试
```bash
npm run test
```

**预期输出**: 所有测试通过

### 5. 使用浏览器测试
- 打开浏览器访问: `http://localhost:3000`
- 访问: `http://localhost:3000/health`

## Mobile 测试步骤

### 1. 检查 Flutter 环境
```bash
flutter doctor
```
确保所有必要的组件都已安装。

### 2. 安装依赖
```bash
cd mobile
flutter pub get
```

### 3. 检查可用设备
```bash
flutter devices
```

### 4. 运行应用
```bash
# 在默认设备上运行
flutter run

# 或指定设备
flutter run -d <device-id>
```

### 5. 验证应用功能
- ✅ 应用正常启动
- ✅ 显示 "Welcome to EduBridge!" 标题
- ✅ 显示计数器文本
- ✅ 点击浮动按钮可以增加计数
- ✅ UI 响应正常

### 6. 运行测试（如果有）
```bash
flutter test
```

## 集成测试

### 测试 Backend 和 Mobile 连接

1. **启动 Backend**
   ```bash
   cd backend
   npm run start:dev
   ```

2. **在 Mobile 应用中配置 API 端点**
   - 修改 `mobile/lib/main.dart` 或创建 API 服务
   - 设置 base URL: `http://localhost:3000` (Android 模拟器使用 `http://10.0.2.2:3000`)

3. **测试 API 调用**
   - 在移动应用中调用健康检查端点
   - 验证响应数据

## 故障排除

### Backend 问题

**端口被占用**
- 修改 `backend/src/main.ts` 中的端口号（例如改为 3001）

**依赖安装失败**
```bash
cd backend
rm -rf node_modules package-lock.json
npm install
```

### Mobile 问题

**设备未连接**
- Android: 启用 USB 调试或启动模拟器
- iOS: 启动模拟器或连接真机

**Flutter 依赖问题**
```bash
cd mobile
flutter clean
flutter pub get
```

**构建错误**
```bash
flutter doctor -v
flutter upgrade
```
