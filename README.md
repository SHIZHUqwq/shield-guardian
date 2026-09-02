# Shield Guardian - 护盾卫士

<div align="center">
  <h1>🛡️ Shield Guardian</h1>
  <p><strong>个人数据泄露应急助手</strong></p>
  <p>帮助用户在遭遇诈骗、数据泄露后快速响应和防护</p>
</div>

## 📱 功能特性

### 🔍 应急检查清单
- ✅ 分步指导被骗后的关键操作
- ✅ 冻结银行卡、修改密码、检查征信等
- ✅ 进度追踪，确保不遗漏重要步骤

### 📢 通知联系人
- ✅ 批量选择通讯录联系人
- ✅ 一键发送安全警告短信
- ✅ 防止诈骗者冒充你进行二次诈骗

### 👁️ 权限监控
- ✅ 实时查看所有敏感权限状态
- ✅ 高/中/低风险分级显示
- ✅ 一键跳转系统设置撤销权限

### 🔒 安全模式
- ✅ 一键启用安全防护模式
- ✅ 持续提醒检查权限
- ✅ 安全建议和最佳实践

### 🚨 诈骗数据库
- ✅ 查询已知诈骗应用信息
- ✅ 提交新的诈骗应用报告
- ✅ 社区共享防护黑名单

## 🎨 设计特点

- **iOS风格界面** - 采用Cupertino设计语言，简洁美观
- **流畅交互** - 原生般的流畅体验
- **清晰层级** - 信息架构清晰，易于理解
- **友好提示** - 每一步都有详细的操作指引

## 📦 技术栈

- **Flutter 3.x** - 跨平台UI框架
- **Cupertino组件** - iOS风格的UI组件库
- **权限管理** - permission_handler
- **本地存储** - shared_preferences
- **联系人** - flutter_contacts
- **短信** - flutter_sms

## 🔧 系统要求

- **Android**: 6.0 (API 23) 及以上
- **存储空间**: 约 50 MB
- **网络**: 无需联网（本地运行）

## 📥 安装使用

### 方法一：安装APK（推荐）
1. 下载编译好的APK文件
2. 在手机设置中允许"安装未知来源应用"
3. 打开APK文件安装
4. 首次运行时授予必要权限

### 方法二：从源码编译
详见下方"开发者指南"

## 🛠️ 开发者指南

### 环境准备

1. **安装Flutter SDK**
```bash
# 下载Flutter SDK到D盘
# 访问: https://flutter.dev/docs/get-started/install/windows

# 配置环境变量
# 将 D:\flutter\bin 添加到 PATH
```

2. **安装Android Studio**
```bash
# 下载并安装Android Studio
# 访问: https://developer.android.com/studio

# 安装Android SDK (API 23-34)
# 安装Android SDK Build-Tools
# 安装Android Emulator (可选)
```

3. **验证环境**
```bash
flutter doctor
```

### 运行项目

1. **克隆项目**
```bash
cd D:\
git clone <your-github-repo-url> shield-guardian
cd shield-guardian
```

2. **安装依赖**
```bash
flutter pub get
```

3. **连接设备或启动模拟器**
```bash
# 查看可用设备
flutter devices

# USB连接真机，或启动Android模拟器
```

4. **运行应用**
```bash
flutter run
```

### 编译APK

```bash
# 编译Release版本APK
flutter build apk --release

# APK位置: build/app/outputs/flutter-apk/app-release.apk
```

### 编译App Bundle (推荐上架Google Play)

```bash
flutter build appbundle --release
```

## 📱 权限说明

应用需要以下权限来提供完整功能：

| 权限 | 用途 | 必需性 |
|------|------|--------|
| 📇 通讯录 | 批量通知联系人功能 | 可选 |
| 💬 短信 | 发送警告短信 | 可选 |
| 📞 电话 | 权限监控功能 | 可选 |
| 📍 位置 | 权限监控功能 | 可选 |
| 📷 相机 | 权限监控功能 | 可选 |
| 🎤 麦克风 | 权限监控功能 | 可选 |
| 💾 存储 | 保存数据 | 推荐 |

**注意**: 所有权限都是可选的。如果拒绝某些权限，相关功能将无法使用，但不影响其他功能。

## 🔒 隐私保护

- ✅ **无需联网** - 所有数据存储在本地
- ✅ **无广告** - 完全免费，无任何广告
- ✅ **开源透明** - 代码完全开源，接受审查
- ✅ **数据安全** - 不收集、不上传任何个人信息

## 📝 使用场景

### 场景1：遭遇诈骗APP
1. 立即打开Shield Guardian
2. 进入"应急检查清单"逐步操作
3. 使用"通知联系人"功能警告家人朋友
4. 在"权限监控"中撤销可疑应用权限
5. 在"诈骗数据库"中提交该应用信息

### 场景2：日常安全检查
1. 定期打开"权限监控"检查
2. 撤销不必要的权限授予
3. 启用"安全模式"获得持续提醒
4. 查看"诈骗数据库"了解最新威胁

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📄 开源协议

MIT License

## 📮 联系方式

- **GitHub Issues**: 报告Bug或功能建议
- **Email**: support@shieldguardian.app (示例)

## ⚠️ 免责声明

本应用仅提供安全防护建议和工具，不能保证完全防止诈骗。遭遇诈骗后请及时报警。

---

<div align="center">
  <p>Made with ❤️ for safer digital life</p>
  <p>让每个人都能更安全地使用手机</p>
</div>
