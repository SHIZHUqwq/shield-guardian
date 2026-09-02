# 🎯 快速开始指南

## 🚀 最简单的方式（推荐）

### 如果你只想使用APP：

1. **等待开发者编译好APK**
2. **下载 `shield-guardian.apk` 文件**
3. **在手机上安装**
4. **开始使用**

详细安装步骤见下方"用户安装指南"。

---

### 如果你想自己编译：

**双击运行**: `build.bat` 
- 它会自动检查环境、安装依赖、编译APK
- 编译完成后会自动打开APK所在文件夹

如果遇到问题，请按照下方"开发者编译指南"操作。

---

## 📱 用户安装指南（安装APK）

### 步骤1：下载APK
从以下途径获取APK文件：
- GitHub Releases页面
- 开发者分享的链接
- 自己编译生成

### 步骤2：允许安装未知应用
1. 打开手机**设置**
2. 搜索"**安装未知应用**"或"**未知来源**"
3. 找到你用来安装的APP（文件管理器/浏览器）
4. 开启"允许安装未知应用"

**不同品牌手机的位置：**
- 小米：设置 → 应用设置 → 应用管理 → 右上角三点 → 安装未知应用
- 华为：设置 → 安全 → 更多安全设置 → 安装外部来源应用
- OPPO：设置 → 其他设置 → 设备与隐私 → 安装外部来源应用
- vivo：设置 → 安全 → 更多设置 → 安装未知应用
- 三星：设置 → 生物识别和安全 → 安装未知应用

### 步骤3：安装应用
1. 找到下载的 `shield-guardian.apk` 或 `app-release.apk`
2. 点击文件
3. 点击"**安装**"
4. 等待安装完成
5. 点击"**打开**"

### 步骤4：首次使用
1. APP会请求存储权限（建议允许，用于保存设置）
2. 其他权限可以暂时拒绝
3. 在使用特定功能时再授予相应权限

**权限说明：**
- 📇 通讯录：用于"通知联系人"功能
- 💬 短信：用于发送警告短信
- 其他权限：仅用于"权限监控"功能的检测

---

## 💻 开发者编译指南（从源码编译）

### 前置要求

#### 1. 安装Flutter SDK

**Windows用户：**

```powershell
# 1. 下载Flutter
# 访问：https://docs.flutter.dev/get-started/install/windows
# 下载最新稳定版（建议3.19.0+）

# 2. 解压到D盘
# 解压到：D:\flutter

# 3. 添加到环境变量
# 系统属性 → 环境变量 → Path → 添加：D:\flutter\bin

# 4. 验证安装
flutter --version
```

#### 2. 安装Android Studio

```powershell
# 1. 下载
# 访问：https://developer.android.com/studio

# 2. 安装Android Studio

# 3. 安装组件
# 打开Android Studio → More Actions → SDK Manager
# 安装：
#   - Android SDK Platform (API 23-34)
#   - Android SDK Build-Tools
#   - Android Emulator (可选)

# 4. 安装Flutter插件
# File → Settings → Plugins → 搜索"Flutter" → Install
```

#### 3. 验证环境

```powershell
flutter doctor
```

理想输出：
```
[✓] Flutter (Channel stable)
[✓] Android toolchain
[✓] Android Studio
```

如果有❌：
```powershell
# 接受Android许可
flutter doctor --android-licenses
```

### 编译步骤

#### 方法1：使用自动脚本（推荐）

```powershell
# 双击运行
D:\shield-guardian\build.bat
```

脚本会自动：
- ✅ 检查Flutter环境
- ✅ 安装项目依赖
- ✅ 清理旧编译
- ✅ 编译Release APK
- ✅ 打开APK所在文件夹

#### 方法2：手动编译

```powershell
# 1. 进入项目目录
cd D:\shield-guardian

# 2. 安装依赖
flutter pub get

# 3. 清理（可选）
flutter clean

# 4. 编译APK
flutter build apk --release

# APK位置：
# D:\shield-guardian\build\app\outputs\flutter-apk\app-release.apk
```

### 高级编译选项

```powershell
# 按架构分别编译（体积更小）
flutter build apk --release --split-per-abi

# 生成3个APK：
# - app-armeabi-v7a-release.apk  (32位，约15MB)
# - app-arm64-v8a-release.apk    (64位，约20MB，推荐)
# - app-x86_64-release.apk       (x86，约20MB)

# 编译调试版本
flutter build apk --debug

# 编译App Bundle（用于Google Play）
flutter build appbundle --release
```

---

## 🐛 常见问题解决

### 问题1：Flutter命令找不到

**症状：** `'flutter' 不是内部或外部命令`

**解决：**
1. 检查Flutter是否安装
2. 检查环境变量PATH是否包含 `D:\flutter\bin`
3. 重启命令行窗口
4. 运行 `flutter --version` 验证

### 问题2：编译失败 - Gradle错误

**症状：** `Gradle build failed`

**解决：**
```powershell
# 方案1：清理重试
flutter clean
flutter pub get
flutter build apk --release

# 方案2：删除gradle缓存
cd D:\shield-guardian\android
rmdir /s /q .gradle
cd ..
flutter build apk --release
```

### 问题3：依赖下载慢

**症状：** `flutter pub get` 卡住不动

**解决：**
```powershell
# 配置国内镜像（中国用户）
# 添加系统环境变量：
# PUB_HOSTED_URL = https://pub.flutter-io.cn
# FLUTTER_STORAGE_BASE_URL = https://storage.flutter-io.cn

# 或者临时使用：
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
flutter pub get
```

### 问题4：Android许可未接受

**症状：** `Android licenses not accepted`

**解决：**
```powershell
flutter doctor --android-licenses
# 然后一路按 'y' 接受
```

### 问题5：缺少Android SDK

**症状：** `Android SDK not found`

**解决：**
```powershell
# 手动指定SDK路径
flutter config --android-sdk C:\Users\你的用户名\AppData\Local\Android\sdk

# 或者安装Android Studio后重新运行
flutter doctor
```

---

## 📤 上传到GitHub

### 步骤1：创建仓库

1. 登录 [GitHub](https://github.com)
2. 点击 **New repository**
3. 仓库名：`shield-guardian`
4. 选择 **Public**
5. ❌ 不要勾选 "Initialize with README"
6. 点击 **Create repository**

### 步骤2：上传代码

```powershell
# 进入项目目录
cd D:\shield-guardian

# 初始化Git
git init

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit: Shield Guardian v1.0.0"

# 添加远程仓库（替换你的用户名）
git remote add origin https://github.com/你的用户名/shield-guardian.git

# 推送
git branch -M main
git push -u origin main
```

### 步骤3：发布Release（可选）

1. 编译APK：`flutter build apk --release`
2. GitHub仓库 → **Releases** → **Create a new release**
3. Tag: `v1.0.0`
4. 标题: `Shield Guardian v1.0.0`
5. 上传APK：`build\app\outputs\flutter-apk\app-release.apk`
6. 点击 **Publish release**

详细步骤见：`GITHUB_UPLOAD.md`

---

## ✅ 检查清单

### 编译前
- [ ] 已安装Flutter SDK
- [ ] 已安装Android Studio
- [ ] `flutter doctor` 无红色错误
- [ ] 能看到 `flutter --version` 输出

### 编译后
- [ ] APK文件已生成
- [ ] 文件大小约20-30MB
- [ ] 能在手机上安装
- [ ] 安装后能正常打开

### 上传GitHub前
- [ ] 已创建GitHub仓库
- [ ] 已安装Git
- [ ] 已配置Git用户名和邮箱

---

## 📚 完整文档

- `README.md` - 项目介绍
- `INSTALL.md` - 详细安装指南
- `GITHUB_UPLOAD.md` - GitHub上传教程
- `PROJECT_REPORT.md` - 项目自检报告
- `build.bat` - 一键编译脚本

---

## 🎉 成功标志

编译成功后你会看到：

```
✓ Built build\app\outputs\flutter-apk\app-release.apk (XX.XMB)
```

APK文件位置：
```
D:\shield-guardian\build\app\outputs\flutter-apk\app-release.apk
```

---

## 📞 需要帮助？

- 查看 `INSTALL.md` 详细教程
- 查看 `PROJECT_REPORT.md` 自检报告
- 在GitHub上提Issue

---

**祝使用愉快！🛡️**
