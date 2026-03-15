# Assets 设置指南

## 📁 文件夹结构

```
mobile/
├── assets/
│   ├── images/
│   │   ├── logo.png          # 主 Logo (推荐: 512x512px)
│   │   ├── logo_light.png   # 浅色 Logo
│   │   ├── logo_dark.png    # 深色 Logo
│   │   └── splash.png       # 启动画面
│   └── fonts/
│       ├── Inter-Regular.ttf
│       ├── Inter-Medium.ttf
│       ├── Inter-SemiBold.ttf
│       └── Inter-Bold.ttf
└── pubspec.yaml
```

## 🖼️ 添加 Logo

### 步骤 1: 准备图片文件

1. 准备 Logo 图片（推荐格式：PNG，透明背景）
2. 推荐尺寸：
   - Logo: 512x512px
   - Icon: 1024x1024px (for app icon)

### 步骤 2: 放置文件

将图片文件复制到 `mobile/assets/images/` 目录：
- `logo.png` - 主 Logo
- `logo_light.png` - 浅色版本（可选）
- `logo_dark.png` - 深色版本（可选）

### 步骤 3: 在代码中使用

```dart
// 在 WelcomePage 中使用
Image.asset(
  'assets/images/logo.png',
  width: 120,
  height: 120,
)

// 在 AppBar 中使用
AppBar(
  leading: Image.asset('assets/images/logo.png'),
)
```

## 🔤 添加字体

### 步骤 1: 下载字体文件

1. 从 [Google Fonts](https://fonts.google.com/specimen/Inter) 下载 Inter 字体
2. 或使用其他字体（如 Roboto, Poppins 等）

### 步骤 2: 放置字体文件

将字体文件复制到 `mobile/assets/fonts/` 目录：
- `Inter-Regular.ttf` (weight: 400)
- `Inter-Medium.ttf` (weight: 500)
- `Inter-SemiBold.ttf` (weight: 600)
- `Inter-Bold.ttf` (weight: 700)

### 步骤 3: 配置 pubspec.yaml

已在 `pubspec.yaml` 中配置：

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

### 步骤 4: 更新 Typography

字体已在 `EduBridgeTypography` 中使用 `Inter` 字体族。

## 📝 使用示例

### Logo 使用示例

```dart
// WelcomePage
Container(
  child: Image.asset(
    'assets/images/logo.png',
    width: 120,
    height: 120,
  ),
)

// AppBar Logo
AppBar(
  title: Row(
    children: [
      Image.asset(
        'assets/images/logo.png',
        width: 32,
        height: 32,
      ),
      const SizedBox(width: 8),
      Text('EduBridge'),
    ],
  ),
)
```

### 字体使用示例

字体已自动应用，无需额外配置。如果需要手动指定：

```dart
Text(
  'Hello',
  style: TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
  ),
)
```

## 🔄 更新 Assets 后

运行以下命令使更改生效：

```bash
cd mobile
flutter pub get
flutter clean
flutter run
```

## ⚠️ 注意事项

1. **文件路径**: 确保文件路径与 `pubspec.yaml` 中的配置一致
2. **文件大小**: 图片文件不要太大，建议压缩
3. **文件格式**: 支持 PNG, JPG, SVG (需要 flutter_svg)
4. **字体文件**: 确保字体文件完整且格式正确
5. **热重载**: 添加新 assets 后需要重启应用（不是热重载）

## 🎨 推荐资源

### Logo 设计工具
- [Canva](https://www.canva.com/)
- [Figma](https://www.figma.com/)

### 字体资源
- [Google Fonts](https://fonts.google.com/)
- [Font Squirrel](https://www.fontsquirrel.com/)

### 图标资源
- [Material Icons](https://fonts.google.com/icons)
- [Flutter Icons](https://pub.dev/packages/flutter_icons)
