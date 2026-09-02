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
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('safe_mode_enabled', value);

    setState(() {
      _safeModeEnabled = value;
      _isLoading = false;
    });

    if (value) {
      _showSafeModeDialog();
    }
  }

  void _showSafeModeDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('安全模式已启用'),
        content: const Text(
          '建议您立即前往系统设置，撤销所有可疑应用的敏感权限。\n\n'
          '特别注意：通讯录、短信、电话、位置等高风险权限。',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('稍后'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('去设置'),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
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
            _buildInfoSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
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
                ? '您的设备处于保护状态'
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
                  '提醒您检查和撤销敏感权限',
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

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '安全模式功能',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: CupertinoIcons.bell_fill,
          title: '持续提醒',
          description: '定期提醒您检查应用权限状态',
          color: CupertinoColors.systemBlue,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: CupertinoIcons.eye_fill,
          title: '权限监控',
          description: '快速查看所有敏感权限的授予情况',
          color: CupertinoColors.systemOrange,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: CupertinoIcons.hand_raised_fill,
          title: '快速撤销',
          description: '一键跳转到系统设置撤销权限',
          color: CupertinoColors.systemGreen,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: CupertinoIcons.info_circle_fill,
          title: '安全建议',
          description: '提供针对性的安全防护建议',
          color: CupertinoColors.systemPurple,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: CupertinoColors.systemBlue,
            borderRadius: BorderRadius.circular(12),
            onPressed: () => openAppSettings(),
            child: const Text('打开系统权限设置'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(12),
            onPressed: () {
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('安全建议'),
                  content: const Text(
                    '1. 定期检查已安装应用列表\n'
                    '2. 卸载不常用的应用\n'
                    '3. 只从官方应用商店下载应用\n'
                    '4. 仔细查看应用权限申请理由\n'
                    '5. 及时更新系统和应用\n'
                    '6. 不要随意开启"无障碍服务"\n'
                    '7. 启用设备锁屏密码',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('知道了'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
            child: const Text(
              '查看安全建议',
              style: TextStyle(color: CupertinoColors.black),
            ),
          ),
        ),
      ],
    );
  }
}
