# EduBridge Monorepo

EduBridge 是一个教育平台项目，采用 monorepo 架构管理多个子项目。

## 📁 项目结构

```
edubridge1/
├── backend/          # NestJS 后端 API
├── mobile/           # Flutter 移动应用
├── docs/             # 项目文档
└── legacy/           # 遗留代码（可选）
```

## 🚀 快速开始

### 前置要求

- **Backend**: Node.js >= 18.0.0, npm 或 yarn
- **Mobile**: Flutter SDK >= 3.0.0, Dart SDK
- **开发工具**: Git, VS Code (推荐)

### Backend (NestJS)

#### 安装依赖
```bash
cd backend
npm install
```

#### 运行开发服务器
```bash
npm run start:dev
```

后端服务将在 `http://localhost:3000` 启动

#### 其他命令
```bash
# 构建项目
npm run build

# 运行生产模式
npm run start:prod

# 运行测试
npm run test

# 代码格式化
npm run format

# 代码检查
npm run lint
```

### Mobile (Flutter)

#### 安装依赖
```bash
cd mobile
flutter pub get
```

#### 运行应用
```bash
# 在连接的设备/模拟器上运行
flutter run

# 运行特定平台
flutter run -d chrome        # Web
flutter run -d android       # Android
flutter run -d ios           # iOS
```

#### 构建应用
```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS
flutter build ios

# Web
flutter build web
```

## 🧪 测试步骤

### Backend 测试

1. **安装依赖**
   ```bash
   cd backend
   npm install
   ```

2. **启动开发服务器**
   ```bash
   npm run start:dev
   ```

3. **验证服务运行**
   - 打开浏览器访问: `http://localhost:3000`
   - 应该看到: `Hello from EduBridge Backend API!`
   - 访问健康检查: `http://localhost:3000/health`
   - 应该返回 JSON: `{"status":"ok","service":"EduBridge Backend","timestamp":"..."}`

4. **运行单元测试**
   ```bash
   npm run test
   ```

### Mobile 测试

1. **检查 Flutter 环境**
   ```bash
   flutter doctor
   ```

## 🐳 Docker (backend + MongoDB)

### Pré-requis
- Docker Desktop installé
- MongoDB sera lancé via `docker-compose`

### Lancer
```bash
docker compose up --build
```

### Arrêter
```bash
docker compose down -v
```

### URL
- API backend : `http://localhost:3000`

## 🚀 Déploiement PFE (production)

### 1) Préparer l'image Docker Hub
```bash
cd backend
docker login
docker build -t nazihadev/edubridge:latest .
docker push nazihadev/edubridge:latest
```

### 2) Préparer les variables production
```bash
cp .env.prod.example .env.prod
```

Renseigner dans `.env.prod` :
- `DOCKERHUB_IMAGE`
- `MONGODB_URI` (MongoDB Atlas recommandé)
- `JWT_SECRET`
- `PORT`

### 3) Déployer
```powershell
.\deploy-prod.ps1
```

### 4) Vérifier
- `http://localhost:3000/api/health`
- `docker compose --env-file .env.prod -f docker-compose.prod.yml logs -f`


2. **安装依赖**
   ```bash
   cd mobile
   flutter pub get
   ```

3. **运行应用**
   ```bash
   flutter run
   ```

4. **验证应用**
   - 应用应该正常启动
   - 主界面显示 "Welcome to EduBridge!"
   - 点击浮动按钮可以增加计数器

## 📚 文档

项目文档位于 `docs/` 目录。可以添加：
- API 文档
- 架构设计文档
- 开发指南
- 部署文档

## 🔧 开发工具配置

### VS Code 推荐扩展

- **Backend**: ESLint, Prettier, TypeScript
- **Mobile**: Flutter, Dart

### Git 配置

项目根目录包含 `.gitignore`，已配置忽略：
- `node_modules/`
- `dist/`
- `.dart_tool/`
- `build/`
- IDE 配置文件

## 📝 项目说明

- **Backend**: 使用 NestJS 框架构建 RESTful API
- **Mobile**: 使用 Flutter 构建跨平台移动应用
- **Monorepo**: 统一管理多个相关项目，便于代码共享和版本控制

## 🤝 贡献指南

1. 从 `main` 分支创建功能分支
2. 进行开发和测试
3. 提交 Pull Request

## 📄 许可证

[在此添加许可证信息]
