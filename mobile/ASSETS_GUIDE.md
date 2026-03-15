# Assets 配置指南

## 📁 文件夹结构

```
mobile/
├── assets/
│   ├── images/
│   │   ├── logo.png          # 主 Logo (已存在)
│   │   ├── logo_light.png   # 浅色 Logo (可选)
│   │   └── logo_dark.png     # 深色 Logo (可选)
│   └── fonts/
│       ├── Inter-Regular.ttf    # 需要添加
│       ├── Inter-Medium.ttf     # 需要添加
│       ├── Inter-SemiBold.ttf   # 需要添加
│       └── Inter-Bold.ttf       # 需要添加
└── pubspec.yaml
```

## 🖼️ 添加 Logo

### 步骤 1: 准备 Logo 文件

1. 准备 Logo 图片（PNG 格式，透明背景）
2. 推荐尺寸：
   - **Logo**: 512x512px 或 1024x1024px
   - **App Icon**: 1024x1024px

### 步骤 2: 放置文件

将 Logo 文件复制到 `mobile/assets/images/` 目录：
- `logo.png` - 主 Logo（已存在占位文件）
- `logo_light.png` - 浅色版本（可选）
- `logo_dark.png` - 深色版本（可选）

### 步骤 3: 使用 Logo

Logo 已在 `WelcomePage` 中配置，会自动加载。如果文件不存在，会显示默认图标。

**代码示例:**
```dart
// 在 WelcomePage 中（已实现）
_buildLogo() // 自动检测并加载 logo.png

// 在其他页面使用
Image.asset(
  'assets/images/logo.png',
  width: 120,
  height: 120,
)
```

## 🔤 添加字体

### 步骤 1: 下载 Inter 字体

1. 访问 [Google Fonts - Inter](https://fonts.google.com/specimen/Inter)
2. 下载字体文件（选择 Regular, Medium, SemiBold, Bold）
3. 或使用其他字体（如 Roboto, Poppins）

### 步骤 2: 放置字体文件

将字体文件复制到 `mobile/assets/fonts/` 目录：
- `Inter-Regular.ttf` (weight: 400)
- `Inter-Medium.ttf` (weight: 500)
- `Inter-SemiBold.ttf` (weight: 600)
- `Inter-Bold.ttf` (weight: 700)

### 步骤 3: 配置已就绪

`pubspec.yaml` 已配置字体：

```yaml
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

### 步骤 4: 应用字体

字体已在 `EduBridgeTypography` 中使用，无需额外配置。

## 🔄 更新后操作

添加或更新 assets 后，运行：

```bash
cd mobile
flutter pub get
flutter clean
flutter run
```

**重要**: 添加新 assets 后需要**重启应用**（不是热重载）

## ✅ 当前状态

- ✅ `assets/images/` 文件夹已创建
- ✅ `assets/fonts/` 文件夹已创建
- ✅ `pubspec.yaml` 已配置 assets 和字体
- ✅ `WelcomePage` 已支持 Logo 加载
- ⚠️ 需要添加实际的 Logo 文件到 `assets/images/logo.png`
- ⚠️ 需要添加字体文件到 `assets/fonts/` 目录

## 📝 快速开始

### 添加 Logo（最简单）

1. 将你的 Logo 文件重命名为 `logo.png`
2. 复制到 `mobile/assets/images/logo.png`
3. 运行 `flutter pub get` 和 `flutter run`

### 添加字体（可选）

1. 下载 Inter 字体文件
2. 复制到 `mobile/assets/fonts/` 目录
3. 运行 `flutter pub get` 和 `flutter run`

如果不添加字体，应用会使用系统默认字体。

## 🎨 推荐工具

### Logo 设计
- [Canva](https://www.canva.com/) - 在线设计工具
- [Figma](https://www.figma.com/) - 专业设计工具

### 字体资源
- [Google Fonts](https://fonts.google.com/) - 免费字体
- [Font Squirrel](https://www.fontsquirrel.com/) - 免费字体

### 图片优化
- [TinyPNG](https://tinypng.com/) - 压缩 PNG 图片
- [Squoosh](https://squoosh.app/) - 图片压缩工具

## ⚠️ 注意事项

1. **文件路径**: 确保文件路径与 `pubspec.yaml` 一致
2. **文件大小**: Logo 建议 < 500KB
3. **文件格式**: 支持 PNG, JPG（SVG 需要额外包）
4. **字体文件**: 确保字体文件完整
5. **重启应用**: 添加 assets 后必须重启，不能热重载
