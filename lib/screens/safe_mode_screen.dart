import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class SafeModeScreen extends StatefulWidget {
  const SafeModeScreen({Key? key}) : super(key: key);

  @override
  State<SafeModeScreen> createState() => _SafeModeScreenState();
}

class _SafeModeScreenState extends State<SafeModeScreen> {
  bool _safeModeEnabled = false;
  bool _isLoading = false;
  Map<String, bool> _protectionStatus = {
    'unknownSources': false,
    'permissions': false,
    'settings': false,
  };

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
          '1. 限制未知来源应用安装\n'
          '2. 检查并提示撤销危险权限\n'
          '3. 提供系统安全设置快捷入口\n\n'
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
        height: MediaQuery.of(context).size.height * 0.6,
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
                      onPressed: () async {
                        Navigator.pop(context);
                        await openAppSettings();
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildProtectionItem(
                      icon: CupertinoIcons.lock_shield,
                      title: '检查应用权限',
                      description: '撤销可疑应用的敏感权限',
                      actionText: '检查权限',
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/permissions');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildProtectionItem(
                      icon: CupertinoIcons.settings,
                      title: '系统安全设置',
                      description: '查看和优化系统安全选项',
                      actionText: '打开设置',
                      onPressed: () async {
                        Navigator.pop(context);
                        await openAppSettings();
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: CupertinoColors.systemBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: CupertinoColors.systemBlue,
              size: 26,
            ),
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
                    fontWeight: FontWeight.w600,
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
                const SizedBox(height: 8),
                CupertinoButton(
                  color: CupertinoColors.systemBlue,
                  borderRadius: BorderRadius.circular(8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  minSize: 0,
                  onPressed: onPressed,
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('安全模式'),
        backgroundColor: Color(0xF0F9F9F9),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            _buildToggleCard(),
            const SizedBox(height: 24),
            _buildProtectionFeatures(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildSecurityTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_safeModeEnabled
                    ? CupertinoColors.systemGreen
                    : CupertinoColors.systemGrey)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _safeModeEnabled
                ? CupertinoIcons.lock_shield_fill
                : CupertinoIcons.lock_slash_fill,
            size: 56,
            color: CupertinoColors.white,
          ),
          const SizedBox(height: 16),
          Text(
            _safeModeEnabled ? '安全模式已启用' : '安全模式未启用',
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _safeModeEnabled
                ? '您的设备正在受到保护'
                : '启用后可增强设备安全性',
            style: const TextStyle(
              color: Color(0xFFE5E5EA),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '启用安全模式',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '提供系统安全保护和权限管理',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          _isLoading
              ? const CupertinoActivityIndicator()
              : CupertinoSwitch(
                  value: _safeModeEnabled,
                  onChanged: _toggleSafeMode,
                ),
        ],
      ),
    );
  }

  Widget _buildProtectionFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '保护功能',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          icon: CupertinoIcons.app_badge,
          title: '应用安装保护',
          description: '引导您限制从未知来源安装应用',
          color: CupertinoColors.systemBlue,
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: CupertinoIcons.eye_fill,
          title: '权限监控提醒',
          description: '持续检查应用权限并提供撤销建议',
          color: CupertinoColors.systemOrange,
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: CupertinoIcons.hand_raised_fill,
          title: '快速安全操作',
          description: '一键访问关键系统安全设置',
          color: CupertinoColors.systemGreen,
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: CupertinoIcons.bell_fill,
          title: '安全提醒通知',
          description: '定期提醒您检查设备安全状态',
          color: CupertinoColors.systemPurple,
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
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
                    fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快速操作',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: CupertinoColors.systemBlue,
            borderRadius: BorderRadius.circular(12),
            onPressed: () => openAppSettings(),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.settings, size: 20),
                SizedBox(width: 8),
                Text('打开系统安全设置'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: CupertinoColors.systemGreen,
            borderRadius: BorderRadius.circular(12),
            onPressed: _showProtectionChecklist,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.checkmark_shield, size: 20),
                SizedBox(width: 8),
                Text('查看保护清单'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityTips() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.lightbulb_fill,
                color: CupertinoColors.systemBlue,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '安全建议',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.systemBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('定期检查已安装应用列表'),
          _buildTipItem('只从官方应用商店下载应用'),
          _buildTipItem('仔细查看应用权限申请理由'),
          _buildTipItem('及时更新系统和应用版本'),
          _buildTipItem('不要随意开启"无障碍服务"'),
          _buildTipItem('启用设备锁屏密码或生物识别'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            CupertinoIcons.checkmark_circle_fill,
            size: 16,
            color: CupertinoColors.systemBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.black,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
