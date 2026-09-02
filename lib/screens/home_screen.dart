import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'checklist_screen.dart';
import 'contacts_alert_screen.dart';
import 'permission_monitor_screen.dart';
import 'safe_mode_screen.dart';
import 'scam_database_screen.dart';
import 'network_monitor_screen.dart';
import 'vpn_traffic_monitor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // iOS 风格大标题导航栏
          CupertinoSliverNavigationBar(
            backgroundColor: const Color(0xFFF2F2F7),
            border: null,
            largeTitle: const Text(
              'Shield Guardian',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.settings,
                size: 24,
              ),
              onPressed: () {
                // 未来添加设置页面
              },
            ),
          ),

          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 欢迎卡片 - 毛玻璃效果
                    _buildWelcomeCard(),

                    const SizedBox(height: 32),

                    // 紧急功能区
                    const Text(
                      '紧急响应',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildFeatureCard(
                      icon: CupertinoIcons.list_bullet_below_rectangle,
                      title: '应急检查清单',
                      subtitle: '被骗后的关键操作步骤',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
                      ),
                      onTap: () => _navigateTo(const ChecklistScreen()),
                    ),

                    const SizedBox(height: 12),

                    _buildFeatureCard(
                      icon: CupertinoIcons.person_2_fill,
                      title: '通知联系人',
                      subtitle: '批量提醒家人朋友防范诈骗',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9500), Color(0xFFFFB340)],
                      ),
                      onTap: () => _navigateTo(const ContactsAlertScreen()),
                    ),

                    const SizedBox(height: 32),

                    // 安全防护区
                    const Text(
                      '安全防护',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallCard(
                            icon: CupertinoIcons.lock_shield_fill,
                            title: '权限监控',
                            color: const Color(0xFF007AFF),
                            onTap: () => _navigateTo(const PermissionMonitorScreen()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSmallCard(
                            icon: CupertinoIcons.hand_raised_fill,
                            title: '安全模式',
                            color: const Color(0xFF34C759),
                            onTap: () => _navigateTo(const SafeModeScreen()),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // 智能检测区
                    const Text(
                      '智能检测',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildFeatureCard(
                      icon: CupertinoIcons.exclamationmark_shield_fill,
                      title: '应用安全扫描',
                      subtitle: '识别手机中的可疑应用',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5856D6), Color(0xFF7B79E8)],
                      ),
                      onTap: () => _navigateTo(const ScamDatabaseScreen()),
                    ),

                    const SizedBox(height: 12),

                    _buildFeatureCard(
                      icon: CupertinoIcons.clock_fill,
                      title: '应用使用监控',
                      subtitle: '查看应用运行时间和后台活动',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFAF52DE), Color(0xFFC77FE8)],
                      ),
                      onTap: () => _navigateTo(const NetworkMonitorScreen()),
                    ),

                    const SizedBox(height: 12),

                    // 核心功能 - 突出显示
                    _buildPremiumCard(
                      icon: CupertinoIcons.antenna_radiowaves_left_right,
                      title: '流量监控',
                      subtitle: '实时检测应用传输的数据类型',
                      badge: '核心',
                      onTap: () => _navigateTo(const VpnTrafficMonitorScreen()),
                    ),

                    const SizedBox(height: 40),

                    // 底部提示
                    _buildFooterTip(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF007AFF),
            Color(0xFF5856D6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.shield_lefthalf_fill,
              color: CupertinoColors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '您的数据安全卫士',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '实时保护您的隐私和个人信息安全',
            style: TextStyle(
              color: CupertinoColors.white.withOpacity(0.9),
              fontSize: 15,
              height: 1.4,
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
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: CupertinoColors.white,
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
                      color: CupertinoColors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                      height: 1.3,
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

  Widget _buildSmallCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.black,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF2D55),
              Color(0xFFFF6482),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF2D55).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 背景装饰
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.white.withOpacity(0.05),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      CupertinoIcons.antenna_radiowaves_left_right,
                      color: CupertinoColors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: CupertinoColors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.white.withOpacity(0.9),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.info_circle_fill,
            color: CupertinoColors.systemGrey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '所有数据在本地分析，不会上传到服务器',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.systemGrey.darkColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
