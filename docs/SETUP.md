# 设置指南

## 完整设置步骤

### 1. 克隆项目（如果从远程仓库）

```bash
git clone <repository-url>
cd edubridge1
```

### 2. Backend 设置

```bash
# 进入 backend 目录
cd backend

# 安装依赖
npm install

# 启动开发服务器
npm run start:dev
```

**验证**: 访问 `http://localhost:3000` 应该看到欢迎消息。

### 3. Mobile 设置

```bash
# 进入 mobile 目录
cd mobile

# 检查 Flutter 环境
flutter doctor

# 安装依赖
flutter pub get

# 运行应用（需要连接设备或启动模拟器）
flutter run
```

### 4. 使用根目录脚本（可选）

```bash
# 从根目录安装所有依赖
npm run install:all

# 启动 backend
npm run backend:dev

# 运行 mobile
npm run mobile:run
```

## 环境要求检查清单

- [ ] Node.js >= 18.0.0 已安装
- [ ] npm 或 yarn 已安装
- [ ] Flutter SDK >= 3.0.0 已安装
- [ ] Dart SDK 已安装
- [ ] Android Studio / Xcode（移动开发）
- [ ] Git 已安装

## 常见问题

### Backend 端口被占用

如果 3000 端口被占用，修改 `backend/src/main.ts` 中的端口号。

### Flutter 设备未连接

确保：
- Android: 启用 USB 调试或启动 Android 模拟器
- iOS: 启动 iOS 模拟器或连接真机

### 依赖安装失败

- Backend: 尝试删除 `node_modules` 和 `package-lock.json`，然后重新安装
- Mobile: 运行 `flutter clean` 然后 `flutter pub get`
