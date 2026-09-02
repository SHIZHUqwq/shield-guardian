import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_usage/app_usage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class NetworkMonitorScreen extends StatefulWidget {
  const NetworkMonitorScreen({Key? key}) : super(key: key);

  @override
  State<NetworkMonitorScreen> createState() => _NetworkMonitorScreenState();
}

class _NetworkMonitorScreenState extends State<NetworkMonitorScreen> {
  List<AppNetworkInfo> _networkApps = [];
  bool _isScanning = false;
  bool _hasScanned = false;
  bool _hasPermission = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    if (Platform.isAndroid) {
      // 检查使用统计权限
      final status = await Permission.scheduleExactAlarm.status;
      setState(() {
        _hasPermission = status.isGranted;
      });
    }
  }

  Future<void> _requestPermission() async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('需要授权'),
        content: const Text(
          '为了监控应用网络使用情况，需要授予"使用情况访问权限"。\n\n'
          '点击"去授权"后，在列表中找到 Shield Guardian 并开启权限。',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('去授权'),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final uri = Uri.parse('android.settings.USAGE_ACCESS_SETTINGS');
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                _showError('无法打开设置');
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _scanNetworkUsage() async {
    if (!_hasPermission) {
      _requestPermission();
      return;
    }

    setState(() => _isScanning = true);

    try {
      // 获取所有已安装应用
      final apps = await InstalledApps.getInstalledApps(false, true);

      // 获取过去24小时的应用使用情况
      final endTime = DateTime.now();
      final startTime = endTime.subtract(const Duration(hours: 24));

      List<AppNetworkInfo> networkInfo = [];

      try {
        final usage = await AppUsage().getAppUsage(startTime, endTime);

        // 创建包名到使用信息的映射
        final usageMap = {for (var u in usage) u.packageName: u};

        for (var app in apps) {
          final appUsage = usageMap[app.packageName];

          // 只显示有使用记录的应用（最近24小时内运行过）
          if (appUsage != null && appUsage.usage.inSeconds > 0) {
            // 估算网络使用（这是一个简化版本，真实网络流量需要更复杂的API）
            // 我们根据应用的使用时长和权限来评估风险
            int riskScore = 0;
            List<String> concerns = [];

            // 检查应用是否在后台长时间运行
            final usageMinutes = appUsage.usage.inMinutes;
            if (usageMinutes > 60) {
              riskScore += 20;
              concerns.add('长时间运行 (${usageMinutes}分钟)');
            }

            // 检查是否是系统应用
            final isSystemApp = app.packageName.startsWith('com.android') ||
                app.packageName.startsWith('com.google');

            if (!isSystemApp) {
              // 检查可疑的包名模式
              if (app.packageName.contains('fake') ||
                  app.packageName.contains('scam')) {
                riskScore += 40;
                concerns.add('包名可疑');
              }

              // 检查应用名称是否包含敏感关键词
              final suspiciousKeywords = [
                '贷款', '借钱', '现金', '赚钱', '清理', '加速',
              ];
              for (var keyword in suspiciousKeywords) {
                if (app.name.contains(keyword)) {
                  riskScore += 15;
                  concerns.add('应用类型可疑');
                  break;
                }
              }

              // 如果应用在后台运行且有风险因素
              if (riskScore > 0) {
                concerns.add('可能正在传输数据');
              }

              networkInfo.add(AppNetworkInfo(
                appInfo: app,
                usageDuration: appUsage.usage,
                riskScore: riskScore,
                concerns: concerns.isEmpty ? ['正常使用'] : concerns,
              ));
            }
          }
        }
      } catch (e) {
        // 如果无法获取使用统计，使用基础扫描
        for (var app in apps) {
          if (!app.packageName.startsWith('com.android') &&
              !app.packageName.startsWith('com.google')) {
            networkInfo.add(AppNetworkInfo(
              appInfo: app,
              usageDuration: Duration.zero,
              riskScore: 0,
              concerns: ['需要使用统计权限查看详情'],
            ));
          }
        }
      }

      // 按风险评分排序
      networkInfo.sort((a, b) => b.riskScore.compareTo(a.riskScore));

      setState(() {
        _networkApps = networkInfo;
        _isScanning = false;
        _hasScanned = true;
      });

      if (networkInfo.isEmpty) {
        _showSuccessDialog('扫描完成', '过去24小时内没有应用显示异常网络活动');
      } else {
        final highRisk = networkInfo.where((a) => a.riskScore >= 30).length;
        if (highRisk > 0) {
          _showWarningDialog(highRisk);
        }
      }
    } catch (e) {
      setState(() => _isScanning = false);
      _showError('扫描失败: $e');
    }
  }

  void _showWarningDialog(int count) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: CupertinoColors.systemOrange,
              size: 24,
            ),
            SizedBox(width: 8),
            Text('发现可疑活动'),
          ],
        ),
        content: Text(
          '发现 $count 个应用存在可疑网络活动\n\n建议立即检查',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('知道了'),
            onPressed: () => Navigator.pop(context),
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

  Future<void> _openAppSettings(String packageName) async {
    try {
      final uri = Uri.parse('package:$packageName');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showError('无法打开应用设置');
    }
  }

  List<AppNetworkInfo> get _filteredApps {
    if (_searchQuery.isEmpty) {
      return _networkApps;
    }
    return _networkApps.where((app) {
      return app.appInfo.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app.appInfo.packageName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('网络监控'),
        backgroundColor: Color(0xF0F9F9F9),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (!_hasPermission) _buildPermissionBanner(),
            if (_hasScanned && _hasPermission) _buildSearchBar(),
            if (_hasScanned && _hasPermission) _buildStatsBar(),
            _buildActionButtons(),
            Expanded(
              child: _hasScanned ? _buildAppList() : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: CupertinoColors.systemYellow.withOpacity(0.2),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: CupertinoColors.systemYellow,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '需要授予使用统计权限才能监控网络活动',
              style: TextStyle(fontSize: 13),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _requestPermission,
            child: const Text('授权', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.antenna_radiowaves_left_right,
            size: 80,
            color: CupertinoColors.systemGrey3,
          ),
          const SizedBox(height: 24),
          const Text(
            '监控网络活动',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              '检测哪些应用正在传输数据\n帮助您发现可疑的数据泄露',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.systemGrey5,
            width: 0.5,
          ),
        ),
      ),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: '搜索应用',
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildStatsBar() {
    final highRisk = _networkApps.where((a) => a.riskScore >= 30).length;
    final mediumRisk = _networkApps.where((a) => a.riskScore >= 10 && a.riskScore < 30).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGrey6,
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.systemGrey5,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: CupertinoIcons.device_phone_portrait,
            label: '监控应用',
            value: '${_networkApps.length}',
            color: CupertinoColors.systemBlue,
          ),
          _buildStatItem(
            icon: CupertinoIcons.exclamationmark_triangle_fill,
            label: '高风险',
            value: '$highRisk',
            color: highRisk > 0 ? CupertinoColors.systemRed : CupertinoColors.systemGreen,
          ),
          _buildStatItem(
            icon: CupertinoIcons.exclamationmark_circle,
            label: '中风险',
            value: '$mediumRisk',
            color: mediumRisk > 0 ? CupertinoColors.systemOrange : CupertinoColors.systemGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.systemGrey5,
            width: 0.5,
          ),
        ),
      ),
      child: CupertinoButton(
        color: CupertinoColors.systemBlue,
        borderRadius: BorderRadius.circular(10),
        padding: const EdgeInsets.symmetric(vertical: 12),
        onPressed: _isScanning ? null : _scanNetworkUsage,
        child: _isScanning
            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.antenna_radiowaves_left_right, size: 18),
                  const SizedBox(width: 6),
                  Text(_hasScanned ? '重新扫描' : '开始监控'),
                ],
              ),
      ),
    );
  }

  Widget _buildAppList() {
    final filteredApps = _filteredApps;

    if (filteredApps.isEmpty && _networkApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.checkmark_shield_fill,
              size: 64,
              color: CupertinoColors.systemGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              '未发现异常网络活动',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '已监控 ${_networkApps.length} 个应用',
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (filteredApps.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.search,
              size: 64,
              color: CupertinoColors.systemGrey3,
            ),
            SizedBox(height: 16),
            Text(
              '没有找到相关应用',
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredApps.length,
      itemBuilder: (context, index) {
        return _buildAppCard(filteredApps[index]);
      },
    );
  }

  Widget _buildAppCard(AppNetworkInfo networkInfo) {
    final app = networkInfo.appInfo;
    Color riskColor;
    String riskText;
    IconData riskIcon;

    if (networkInfo.riskScore >= 30) {
      riskColor = CupertinoColors.systemRed;
      riskText = '高风险';
      riskIcon = CupertinoIcons.exclamationmark_octagon_fill;
    } else if (networkInfo.riskScore >= 10) {
      riskColor = CupertinoColors.systemOrange;
      riskText = '中风险';
      riskIcon = CupertinoIcons.exclamationmark_triangle_fill;
    } else {
      riskColor = CupertinoColors.systemGreen;
      riskText = '正常';
      riskIcon = CupertinoIcons.checkmark_circle_fill;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: riskColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: riskColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: app.icon != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(app.icon!, fit: BoxFit.cover),
                      )
                    : Icon(riskIcon, color: riskColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.packageName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.systemGrey,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  riskText,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (networkInfo.usageDuration.inSeconds > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.time,
                    size: 16,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '过去24小时运行: ${networkInfo.usageDuration.inMinutes} 分钟',
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '监控发现：',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ...networkInfo.concerns.map((concern) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Text(
                              concern,
                              style: const TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: riskColor,
            borderRadius: BorderRadius.circular(8),
            onPressed: () => _openAppSettings(app.packageName),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.settings, size: 16),
                SizedBox(width: 6),
                Text('查看应用详情', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppNetworkInfo {
  final AppInfo appInfo;
  final Duration usageDuration;
  final int riskScore;
  final List<String> concerns;

  AppNetworkInfo({
    required this.appInfo,
    required this.usageDuration,
    required this.riskScore,
    required this.concerns,
  });
}
