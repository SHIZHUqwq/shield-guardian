import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'checklist_screen.dart';
import 'contacts_alert_screen.dart';
import 'permission_monitor_screen.dart';
import 'safe_mode_screen.dart';
import 'scam_database_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Shield Guardian'),
        backgroundColor: Color(0xF0F9F9F9),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 20),
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildFeatureCard(
              icon: CupertinoIcons.checkmark_shield_fill,
              title: '应急检查清单',
              subtitle: '被骗后的关键步骤指导',
              color: CupertinoColors.systemBlue,
              onTap: () => _navigateTo(const ChecklistScreen()),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: CupertinoIcons.person_2_fill,
              title: '通知联系人',
              subtitle: '批量提醒家人朋友注意防范',
              color: CupertinoColors.systemGreen,
              onTap: () => _navigateTo(const ContactsAlertScreen()),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: CupertinoIcons.eye_fill,
              title: '权限监控',
              subtitle: '查看哪些应用正在使用敏感权限',
              color: CupertinoColors.systemOrange,
              onTap: () => _navigateTo(const PermissionMonitorScreen()),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: CupertinoIcons.lock_shield_fill,
              title: '安全模式',
              subtitle: '一键限制所有应用的敏感权限',
              color: CupertinoColors.systemRed,
              onTap: () => _navigateTo(const SafeModeScreen()),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: CupertinoIcons.exclamationmark_triangle_fill,
              title: '诈骗数据库',
              subtitle: '查询和提交诈骗应用信息',
              color: CupertinoColors.systemPurple,
              onTap: () => _navigateTo(const ScamDatabaseScreen()),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF007AFF),
            Color(0xFF5856D6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(
            CupertinoIcons.shield_fill,
            color: CupertinoColors.white,
            size: 40,
          ),
          SizedBox(height: 12),
          Text(
            '您的数据安全卫士',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '遭遇诈骗后的应急工具\n帮助您快速响应，减少损失',
            style: TextStyle(
              color: Color(0xFFE5E5EA),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
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
                      color: CupertinoColors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey3,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => screen),
    );
  }
}
