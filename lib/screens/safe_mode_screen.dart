import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class SafeModeScreen extends StatefulWidget {
  const SafeModeScreen({Key? key}) : super(key: key);

  @override
  State<SafeModeScreen> createState() => _SafeModeScreenState();
}

class _SafeModeScreenState extends State<SafeModeScreen> {
  bool _safeModeEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSafeModeStatus();
  }

  Future<void> _loadSafeModeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _safeModeEnabled = prefs.getBool('safe_mode_enabled') ?? false;
    });
  }

  Future<void> _toggleSafeMode(bool value) async {
    if (value) {
      _showEnableConfirmation();
    } else {
      _disableSafeMode();
    }
  }

  void _showEnableConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('启用安全模式'),
        content: const Text(
          '安全模式将帮助您：\n\n'
          '1. 引导限制未知来源应用安装\n'
          '2. 引导检查并撤销危险权限\n'
          '3. 提供系统安全设置快捷入口\n\n'
          '注意：由于Android系统限制，我们无法自动修改系统设置，但会引导您手动完成\n\n'
          '是否继续？',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('启用'),
            onPressed: () {
              Navigator.pop(context);
              _enableSafeMode();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _enableSafeMode() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('safe_mode_enabled', true);

    setState(() {
      _safeModeEnabled = true;
      _isLoading = false;
    });

    _showProtectionGuide();
  }

  Future<void> _disableSafeMode() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('safe_mode_enabled', false);

    setState(() {
      _safeModeEnabled = false;
      _isLoading = false;
    });

    _showSuccessDialog('安全模式已关闭', '您可以随时重新启用安全保护');
  }

  void _showProtectionGuide() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.checkmark_shield_fill,
              color: CupertinoColors.systemGreen,
              size: 24,
            ),
            SizedBox(width: 8),
            Text('安全模式已启用'),
          ],
        ),
        content: const Text(
          '为了获得最佳保护，建议您完成以下安全设置：\n\n'
          '1. 限制未知来源应用安装\n'
          '2. 检查并撤销可疑应用权限\n'
          '3. 启用系统安全功能\n\n'
          '现在开始设置？',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('稍后'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('立即设置'),
            onPressed: () {
              Navigator.pop(context);
              _showProtectionChecklist();
            },
          ),
        ],
      ),
    );
  }

  void _showProtectionChecklist() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.systemGrey5,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '安全保护清单',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('完成'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildProtectionItem(
                      icon: CupertinoIcons.app_badge,
                      title: '限制未知来源安装',
                      description: '防止从非官方渠道安装恶意应用',
                      actionText: '去设置',
                      onPressed: () {
                        Navigator.pop(context);
                        _openUnknownSourcesSettings();
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildProtectionItem(
                      icon: CupertinoIcons.lock_shield,
                      title: '检查应用权限',
                      description: '撤销可疑应用的敏感权限（通讯录、位置等）',
                      actionText: '权限管理',
                      onPressed: () {
                        Navigator.pop(context);
                        _openPermissionSettings();
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildProtectionItem(
                      icon: CupertinoIcons.lock_fill,
                      title: '应用锁定',
                      description: '为敏感应用设置密码或指纹保护',
                      actionText: '安全中心',
                      onPressed: () {
                        Navigator.pop(context);
                        _openSecuritySettings();
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildProtectionItem(
                      icon: CupertinoIcons.wifi,
                      title: '网络安全',
                      description: '检查WiFi和网络连接安全性',
                      actionText: '网络设置',
                      onPressed: () {
                        Navigator.pop(context);
                        _openWifiSettings();
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildProtectionItem(
                      icon: CupertinoIcons.location_fill,
                      title: '位置权限',
                      description: '管理应用的位置访问权限',
                      actionText: '位置设置',
                      onPressed: () {
                        Navigator.pop(context);
                        _openLocationSettings();
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildProtectionItem(
                      icon: CupertinoIcons.doc_text_search,
                      title: '系统更新',
                      description: '保持系统安全补丁为最新版本',
                      actionText: '检查更新',
                      onPressed: () {
                        Navigator.pop(context);
                        _openSystemUpdateSettings();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUnknownSourcesSettings() async {
    try {
      if (Platform.isAndroid) {
        // Android 8.0+: 每个应用单独的未知来源权限
        final uri = Uri.parse('android.settings.MANAGE_UNKNOWN_APP_SOURCES');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // 降级到旧版设置
          final fallbackUri = Uri.parse('android.settings.SECURITY_SETTINGS');
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      _showError('无法打开设置，请手动进入：设置 > 安全 > 未知来源');
    }
  }

  Future<void> _openPermissionSettings() async {
    try {
      final uri = Uri.parse('android.settings.MANAGE_APPLICATIONS_SETTINGS');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showError('无法打开设置');
    }
  }

  Future<void> _openSecuritySettings() async {
    try {
      final uri = Uri.parse('android.settings.SECURITY_SETTINGS');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showError('无法打开设置');
    }
  }

  Future<void> _openWifiSettings() async {
    try {
      final uri = Uri.parse('android.settings.WIFI_SETTINGS');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showError('无法打开设置');
    }
  }

  Future<void> _openLocationSettings() async {
    try {
      final uri = Uri.parse('android.settings.LOCATION_SOURCE_SETTINGS');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showError('无法打开设置');
    }
  }

  Future<void> _openSystemUpdateSettings() async {
    try {
      final uri = Uri.parse('android.settings.SYSTEM_UPDATE_SETTINGS');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final fallbackUri = Uri.parse('android.settings.SETTINGS');
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showError('无法打开设置');
    }
  }

  Widget _buildProtectionItem({
    required IconData icon,
    required String title,
    required String description,
    required String actionText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: CupertinoColors.systemBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: CupertinoColors.systemBlue,
            borderRadius: BorderRadius.circular(8),
            onPressed: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.arrow_right_circle, size: 16),
                const SizedBox(width: 6),
                Text(actionText, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: const Color(0xFFF2F2F7),
            border: null,
            largeTitle: const Text(
              '安全模式',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 32),
                  _buildFeaturesSection(),
                  const SizedBox(height: 32),
                  _buildQuickActionsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _safeModeEnabled
              ? [
                  const Color(0xFF34C759),
                  const Color(0xFF30D158),
                ]
              : [
                  const Color(0xFF8E8E93),
                  const Color(0xFFAEAEB2),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_safeModeEnabled ? const Color(0xFF34C759) : const Color(0xFF8E8E93)).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _safeModeEnabled
                  ? CupertinoIcons.shield_fill
                  : CupertinoIcons.shield_slash_fill,
              size: 56,
              color: CupertinoColors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _safeModeEnabled ? '安全模式已启用' : '安全模式已关闭',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _safeModeEnabled
                ? '您的设备正在受到保护'
                : '启用安全模式以获得更好的保护',
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const CupertinoActivityIndicator(color: CupertinoColors.white)
          else
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: CupertinoColors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CupertinoSwitch(
                value: _safeModeEnabled,
                onChanged: _toggleSafeMode,
                activeColor: CupertinoColors.white,
                trackColor: CupertinoColors.white.withOpacity(0.3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '安全功能',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          icon: CupertinoIcons.app_badge,
          title: '应用安装保护',
          description: '引导限制未知来源应用的安装',
          enabled: _safeModeEnabled,
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: CupertinoIcons.lock_shield,
          title: '权限监控',
          description: '帮助检查和管理应用权限',
          enabled: _safeModeEnabled,
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: CupertinoIcons.checkmark_shield,
          title: '安全引导',
          description: '提供系统安全设置的快捷入口',
          enabled: _safeModeEnabled,
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? const Color(0xFF34C759).withOpacity(0.3)
              : const Color(0xFFE5E5EA),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: enabled
                  ? const Color(0xFF34C759).withOpacity(0.15)
                  : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: enabled
                  ? const Color(0xFF34C759)
                  : CupertinoColors.systemGrey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            enabled ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
            color: enabled ? const Color(0xFF34C759) : CupertinoColors.systemGrey4,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快捷操作',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _safeModeEnabled ? _showProtectionChecklist : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: _safeModeEnabled
                  ? const LinearGradient(
                      colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: _safeModeEnabled ? null : const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _safeModeEnabled
                  ? [
                      BoxShadow(
                        color: const Color(0xFF007AFF).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.checkmark_shield_fill,
                  color: _safeModeEnabled
                      ? CupertinoColors.white
                      : CupertinoColors.systemGrey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '查看安全保护清单',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _safeModeEnabled
                        ? CupertinoColors.white
                        : CupertinoColors.systemGrey,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
