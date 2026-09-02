# Shield Guardian 安装使用指南

## 📱 用户安装指南

### 方式一：直接安装APK（最简单）

#### 步骤1：获取APK文件
1. 从GitHub Releases下载 `shield-guardian.apk`
2. 或者找开发者要编译好的APK文件

#### 步骤2：允许安装未知来源
1. 打开手机**设置**
2. 进入 **安全与隐私** 或 **应用管理**
3. 找到 **安装未知应用** 或 **特殊权限**
4. 选择你用来安装的应用（如文件管理器、浏览器）
5. 允许该应用安装未知来源应用

#### 步骤3：安装应用
1. 找到下载的APK文件
2. 点击安装
3. 等待安装完成
4. 点击"打开"启动应用

#### 步骤4：授予权限（可选）
首次打开时，应用会请求以下权限：
- ✅ **存储权限**（推荐）：保存您的设置
- ⚠️ **通讯录权限**：仅在使用"通知联系人"功能时需要
- ⚠️ **短信权限**：仅在发送通知短信时需要
- ℹ️ 其他权限：仅用于权限监控功能，可以拒绝

**注意**：拒绝权限不影响其他功能的使用！

---

## 💻 开发者完整指南

### 一、环境准备

#### 1. 安装Flutter SDK

**Windows系统：**

```powershell
# 1. 下载Flutter SDK
# 访问 https://docs.flutter.dev/get-started/install/windows
# 下载最新稳定版 (推荐3.19.0或更高)

# 2. 解压到D盘
# 解压到 D:\flutter

# 3. 配置环境变量
# 右键"此电脑" -> "属性" -> "高级系统设置" -> "环境变量"
# 在"系统变量"中找到"Path"，点击"编辑"
# 添加：D:\flutter\bin

# 4. 验证安装
flutter --version
```

#### 2. 安装Android Studio

```powershell
# 1. 下载Android Studio
# 访问 https://developer.android.com/studio
# 下载最新版本

# 2. 安装Android Studio
# 双击安装包，按照向导完成安装

# 3. 首次启动配置
# - 选择 "Standard" 安装类型
# - 等待下载 Android SDK
# - 安装 Android SDK Platform (API 23-34)
# - 安装 Android SDK Build-Tools

# 4. 安装Flutter插件
# 打开Android Studio
# File -> Settings -> Plugins
# 搜索 "Flutter" 并安装
# 搜索 "Dart" 并安装
# 重启Android Studio
```

#### 3. 验证开发环境

```powershell
# 运行Flutter诊断
flutter doctor

# 理想输出应该是：
# [✓] Flutter (Channel stable, 3.x.x)
# [✓] Android toolchain - develop for Android devices
# [✓] Android Studio (version 2023.x)
# [✓] Connected device (如果连接了设备)
```

**常见问题解决：**

```powershell
# 问题1：找不到Android SDK
flutter config --android-sdk D:\Android\sdk

# 问题2：许可证未接受
flutter doctor --android-licenses
# 然后一路按 'y' 接受

# 问题3：找不到Java
# 下载并安装 JDK 11 或更高版本
# 配置 JAVA_HOME 环境变量
```

### 二、运行项目

#### 1. 获取项目代码

```powershell
# 方式1：从GitHub克隆（如果已上传）
cd D:\
git clone https://github.com/your-username/shield-guardian.git
cd shield-guardian

# 方式2：直接使用现有项目
cd D:\shield-guardian
```

#### 2. 安装依赖

```powershell
# 获取所有Flutter依赖包
flutter pub get

# 等待下载完成，看到 "Got dependencies!" 表示成功
```

#### 3. 连接测试设备

**选项A：使用真实Android手机（推荐）**

```powershell
# 1. 手机开启开发者模式
# - 进入设置 -> 关于手机
# - 连续点击"版本号"7次
# - 返回设置，找到"开发者选项"

# 2. 开启USB调试
# - 进入"开发者选项"
# - 打开"USB调试"

# 3. 用USB线连接手机和电脑
# - 手机会弹出授权提示，点击"允许"

# 4. 验证连接
flutter devices

# 应该看到你的手机型号
```

**选项B：使用Android模拟器**

```powershell
# 1. 在Android Studio中创建模拟器
# Tools -> Device Manager -> Create Device
# 选择一个设备型号（如Pixel 6）
# 选择系统镜像（推荐API 30或更高）
# 完成创建

# 2. 启动模拟器
# 在Device Manager中点击启动按钮

# 3. 验证
flutter devices
```

#### 4. 运行应用

```powershell
# Debug模式运行（开发时使用）
flutter run

# 如果有多个设备，指定设备
flutter run -d <device-id>

# 热重载：在运行时按 'r' 键
# 热重启：在运行时按 'R' 键
# 退出：按 'q' 键
```

### 三、编译APK

#### 编译Release版本

```powershell
# 1. 清理之前的构建
flutter clean

# 2. 获取依赖
flutter pub get

# 3. 编译APK
flutter build apk --release

# 等待编译完成...
# 成功后APK位置：
# D:\shield-guardian\build\app\outputs\flutter-apk\app-release.apk
```

#### 编译优化版本（更小体积）

```powershell
# 按CPU架构分别编译（体积更小）
flutter build apk --release --split-per-abi

# 会生成3个APK：
# - app-armeabi-v7a-release.apk  (32位设备)
# - app-arm64-v8a-release.apk    (64位设备，最常用)
# - app-x86_64-release.apk       (模拟器/x86设备)
```

### 四、测试APK

```powershell
# 在连接的设备上安装并运行APK
flutter install

# 或者手动安装
adb install build\app\outputs\flutter-apk\app-release.apk

# 卸载应用
adb uninstall com.shieldguardian.app
```

### 五、常见问题

#### 问题1：编译失败 - Gradle错误

```powershell
# 解决方案1：清理缓存
flutter clean
flutter pub get
flutter build apk

# 解决方案2：更新Gradle
# 编辑 android\gradle\wrapper\gradle-wrapper.properties
# 修改：distributionUrl=https\://services.gradle.org/distributions/gradle-7.6-all.zip
```

#### 问题2：依赖下载慢

```powershell
# 配置国内镜像（中国用户）
# 在系统环境变量中添加：
# PUB_HOSTED_URL=https://pub.flutter-io.cn
# FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

#### 问题3：权限相关API报错

```powershell
# 确保使用了正确的Android SDK版本
# 编辑 android\app\build.gradle
# 确认：
# compileSdkVersion 34
# minSdkVersion 23
# targetSdkVersion 34
```

#### 问题4：签名问题（用于发布）

```powershell
# 1. 生成密钥
keytool -genkey -v -keystore D:\shield-guardian\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. 创建 android\key.properties
storePassword=你的密码
keyPassword=你的密码
keyAlias=upload
storeFile=D:\\shield-guardian\\upload-keystore.jks

# 3. 修改 android\app\build.gradle
# 添加签名配置（详见Flutter官方文档）
```

### 六、性能优化

```powershell
# 1. 分析APK大小
flutter build apk --analyze-size

# 2. 启用代码混淆和压缩
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# 3. 查看应用体积
ls -lh build\app\outputs\flutter-apk\app-release.apk
```

### 七、调试技巧

```powershell
# 查看日志
flutter logs

# 查看设备日志
adb logcat

# 仅查看Flutter日志
adb logcat -s flutter

# 性能分析
flutter run --profile
# 然后在DevTools中查看性能
```

---

## 🎯 快速开始（5分钟版）

```powershell
# 1. 安装Flutter（一次性）
# 下载：https://docs.flutter.dev/get-started/install/windows
# 解压到D:\flutter，添加到PATH

# 2. 进入项目
cd D:\shield-guardian

# 3. 安装依赖
flutter pub get

# 4. 连接手机（开启USB调试）

# 5. 运行
flutter run

# 6. 编译APK
flutter build apk --release
```

**APK位置：** `D:\shield-guardian\build\app\outputs\flutter-apk\app-release.apk`

---

## 📞 需要帮助？

- 查看 [Flutter官方文档](https://docs.flutter.dev/)
- 查看 [Android开发文档](https://developer.android.com/)
- 在GitHub上提Issue

---

## ✅ 检查清单

编译前确认：
- ✅ Flutter SDK已安装并配置PATH
- ✅ Android Studio已安装
- ✅ `flutter doctor` 无红色错误
- ✅ `flutter pub get` 成功
- ✅ 能看到设备 `flutter devices`

编译后确认：
- ✅ APK文件生成在 `build\app\outputs\flutter-apk\`
- ✅ APK能在真机上安装运行
- ✅ 所有功能正常工作
