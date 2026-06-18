# 小龟寻物

小龟寻物是一款 Android App，用来拍下东西放在哪里，并在之后用自然语言找回来。

核心功能：

- 拍照后照片只保存在 App 私有目录。
- 使用 MiMo `mimo-v2.5` 自动生成物品记忆卡。
- 支持用自然语言查找物品位置。
- 没有 API Key、没网、GPS 失败或 AI 失败时，照片不丢，记录可重试。

开发设计见：

`../docs/superpowers/specs/2026-06-18-xiaogui-xunwu-design.md`

## 本地运行

首次运行前先安装依赖：

```sh
flutter pub get
```

连接 Android 手机或模拟器后运行：

```sh
flutter run
```

进入 App 右上角设置，填写 MiMo API Key。Key 只保存在本机安全存储里，不会写入源码。

## 打包 APK

生成 debug APK：

```sh
scripts/build_debug_apk.sh
```

APK 输出位置：

```text
build/app/outputs/flutter-apk/小龟寻物-debug.apk
```
