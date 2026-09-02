import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class ScamDatabaseScreen extends StatefulWidget {
  const ScamDatabaseScreen({Key? key}) : super(key: key);

  @override
  State<ScamDatabaseScreen> createState() => _ScamDatabaseScreenState();
}

class _ScamDatabaseScreenState extends State<ScamDatabaseScreen> {
  List<AppInfo> _allApps = [];
  List<SuspiciousApp> _suspiciousApps = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isScanning = false;
  bool _hasScanned = false;

  final List<String> _scamKeywords = [
    '贷款', '借钱', '现金', '急用钱', '极速', '快速',
    '清理', '加速', '优化', '管家',
    '赚钱', '兼职', '刷单', '红包', '返利',
    '交友', '约会', '美女',
    '彩票', '博彩', '赌',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanInstalledApps() async {
    setState(() => _isScanning = true);

    try {
      // 获取所有已安装应用
      final apps = await InstalledApps.getInstalledApps(false, true);

      List<SuspiciousApp> suspicious = [];

      for (var app in apps) {
        int riskScore = 0;
        List<String> reasons = [];

        // 检查应用名称是否包含可疑关键词
        for (var keyword in _scamKeywords) {
          if (app.name.contains(keyword)) {
            riskScore += 20;
            reasons.add('应用名称包含敏感词："$keyword"');
            break;
          }
        }

        // 检查包名是否可疑
        if (app.packageName.contains('fake') ||
            app.packageName.contains('scam') ||
            app.packageName.contains('test')) {
          riskScore += 30;
          reasons.add('包名可疑');
        }

        // 简单的风险评估：应用名很短或包含数字
        if (app.name.length < 3 || RegExp(r'\d{3,}').hasMatch(app.name)) {
          riskScore += 10;
          reasons.add('应用名称格式异常');
        }

        if (riskScore > 0) {
          suspicious.add(SuspiciousApp(
            appInfo: app,
            riskScore: riskScore,
            reasons: reasons,
          ));
        }
      }

      // 按风险评分排序
      suspicious.sort((a, b) => b.riskScore.compareTo(a.riskScore));

      setState(() {
        _allApps = apps;
        _suspiciousApps = suspicious;
        _isScanning = false;
        _hasScanned = true;
      });

      if (suspicious.isEmpty) {
        _showSuccessDialog('扫描完成', '未发现可疑应用，您的设备很安全！\n\n共扫描 ${apps.length} 个应用');
      } else {
        _showSuspiciousDialog(suspicious.length);
      }
    } catch (e) {
      setState(() => _isScanning = false);
      _showError('扫描失败: $e');
    }
  }

  void _showSuspiciousDialog(int count) {
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
            Text('发现可疑应用'),
          ],
        ),
        content: Text(
          '在您的设备上发现 $count 个可疑应用\n\n请仔细检查并考虑卸载',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('知道了'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('去查看'),
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.checkmark_shield_fill,
              color: CupertinoColors.systemGreen,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
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

  Future<void> _shareScamList() async {
    if (!_hasScanned) {
      _showError('请先扫描手机');
      return;
    }

    try {
      final StringBuffer content = StringBuffer();
      content.writeln('⚠️ 手机应用安全扫描报告 ⚠️');
      content.writeln('');
      content.writeln('扫描时间：${DateTime.now().toString().substring(0, 19)}');
      content.writeln('共扫描应用：${_allApps.length} 个');
      content.writeln('可疑应用数：${_suspiciousApps.length} 个');
      content.writeln('');

      if (_suspiciousApps.isEmpty) {
        content.writeln('✅ 未发现可疑应用，设备安全！');
      } else {
        content.writeln('═══════════════════');
        content.writeln('🚨 可疑应用列表：');
        content.writeln('');

        for (var i = 0; i < _suspiciousApps.length; i++) {
          final app = _suspiciousApps[i];
          final riskLevel = app.riskScore >= 40 ? '🔴 高风险' :
                           app.riskScore >= 20 ? '🟠 中风险' : '🟡 低风险';

          content.writeln('${i + 1}. ${app.appInfo.name}');
          content.writeln('   风险等级：$riskLevel (${app.riskScore}分)');
          content.writeln('   包名：${app.appInfo.packageName}');
          content.writeln('   原因：${app.reasons.join('、')}');
          content.writeln('');
        }
      }

      content.writeln('═══════════════════');
      content.writeln('');
      content.writeln('📢 建议：');
      content.writeln('• 卸载不明来源的可疑应用');
      content.writeln('• 定期检查应用权限');
      content.writeln('• 只从官方渠道下载应用');
      content.writeln('');
      content.writeln('⚡ 来自 Shield Guardian 防诈骗助手');

      await Share.share(
        content.toString(),
        subject: '手机应用安全扫描报告',
      );
    } catch (e) {
      _showError('分享失败: $e');
    }
  }

  Future<void> _exportReport() async {
    if (!_hasScanned) {
      _showError('请先扫描手机');
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/scan_report_${DateTime.now().millisecondsSinceEpoch}.txt');

      final StringBuffer content = StringBuffer();
      content.writeln('═══════════════════════════════════');
      content.writeln('    手机应用安全扫描报告');
      content.writeln('═══════════════════════════════════');
      content.writeln('');
      content.writeln('报告生成时间：${DateTime.now().toString().substring(0, 19)}');
      content.writeln('扫描应用总数：${_allApps.length} 个');
      content.writeln('可疑应用数量：${_suspiciousApps.length} 个');
      content.writeln('');
      content.writeln('═══════════════════════════════════');
      content.writeln('');

      if (_suspiciousApps.isEmpty) {
        content.writeln('✅ 扫描结果：未发现可疑应用');
        content.writeln('');
        content.writeln('您的设备目前看起来很安全！');
      } else {
        content.writeln('🚨 可疑应用详情：');
        content.writeln('');

        for (var i = 0; i < _suspiciousApps.length; i++) {
          final app = _suspiciousApps[i];
          final riskLevel = app.riskScore >= 40 ? '高风险' :
                           app.riskScore >= 20 ? '中风险' : '低风险';

          content.writeln('【${i + 1}】 ${app.appInfo.name}');
          content.writeln('─────────────────────────────────');
          content.writeln('包名：${app.appInfo.packageName}');
          content.writeln('版本：${app.appInfo.versionName}');
          content.writeln('风险等级：$riskLevel');
          content.writeln('风险评分：${app.riskScore} 分');
          content.writeln('可疑原因：');
          for (var reason in app.reasons) {
            content.writeln('  • $reason');
          }
          content.writeln('');
        }
      }

      content.writeln('═══════════════════════════════════');
      content.writeln('');
      content.writeln('安全建议：');
      content.writeln('1. 卸载所有不明来源的应用');
      content.writeln('2. 定期检查应用权限设置');
      content.writeln('3. 只从官方应用商店下载应用');
      content.writeln('4. 不要轻易授予敏感权限');
      content.writeln('5. 遇到诈骗及时报警');
      content.writeln('');
      content.writeln('═══════════════════════════════════');
      content.writeln('由 Shield Guardian 生成');

      await file.writeAsString(content.toString());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '手机应用安全扫描报告',
        text: '这是我的手机安全扫描报告',
      );
    } catch (e) {
      _showError('导出失败: $e');
    }
  }

  List<SuspiciousApp> get _filteredApps {
    if (_searchQuery.isEmpty) {
      return _suspiciousApps;
    }
    return _suspiciousApps.where((app) {
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
      navigationBar: CupertinoNavigationBar(
        middle: const Text('应用安全扫描'),
        backgroundColor: const Color(0xF0F9F9F9),
        trailing: _hasScanned
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.share),
                onPressed: _exportReport,
              )
            : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_hasScanned) _buildSearchBar(),
            if (_hasScanned) _buildStatsBar(),
            _buildActionButtons(),
            Expanded(
              child: _hasScanned ? _buildAppList() : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.device_phone_portrait,
            size: 80,
            color: CupertinoColors.systemGrey3,
          ),
          const SizedBox(height: 24),
          const Text(
            '扫描您的手机',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              '点击"扫描手机"按钮，检测可疑应用\n帮助您保护设备安全',
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
        placeholder: '搜索应用名称或包名',
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildStatsBar() {
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
            label: '已扫描',
            value: '${_allApps.length}',
            color: CupertinoColors.systemBlue,
          ),
          _buildStatItem(
            icon: CupertinoIcons.exclamationmark_triangle_fill,
            label: '可疑应用',
            value: '${_suspiciousApps.length}',
            color: _suspiciousApps.isEmpty
                ? CupertinoColors.systemGreen
                : CupertinoColors.systemOrange,
          ),
          _buildStatItem(
            icon: _suspiciousApps.isEmpty
                ? CupertinoIcons.checkmark_shield_fill
                : CupertinoIcons.shield_slash_fill,
            label: '安全等级',
            value: _suspiciousApps.isEmpty ? '安全' : '警告',
            color: _suspiciousApps.isEmpty
                ? CupertinoColors.systemGreen
                : CupertinoColors.systemRed,
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
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              color: CupertinoColors.systemBlue,
              borderRadius: BorderRadius.circular(10),
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: _isScanning ? null : _scanInstalledApps,
              child: _isScanning
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.search, size: 18),
                        const SizedBox(width: 6),
                        Text(_hasScanned ? '重新扫描' : '扫描手机'),
                      ],
                    ),
            ),
          ),
          if (_hasScanned) ...[
            const SizedBox(width: 12),
            Expanded(
              child: CupertinoButton(
                color: CupertinoColors.systemGreen,
                borderRadius: BorderRadius.circular(10),
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _shareScamList,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.share, size: 18),
                    SizedBox(width: 6),
                    Text('分享报告'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppList() {
    final filteredApps = _filteredApps;

    if (filteredApps.isEmpty && _suspiciousApps.isEmpty) {
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
              '未发现可疑应用',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '已扫描 ${_allApps.length} 个应用',
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

  Widget _buildAppCard(SuspiciousApp suspiciousApp) {
    final app = suspiciousApp.appInfo;
    Color riskColor;
    String riskText;
    IconData riskIcon;

    if (suspiciousApp.riskScore >= 40) {
      riskColor = CupertinoColors.systemRed;
      riskText = '高风险';
      riskIcon = CupertinoIcons.xmark_octagon_fill;
    } else if (suspiciousApp.riskScore >= 20) {
      riskColor = CupertinoColors.systemOrange;
      riskText = '中风险';
      riskIcon = CupertinoIcons.exclamationmark_triangle_fill;
    } else {
      riskColor = CupertinoColors.systemYellow;
      riskText = '低风险';
      riskIcon = CupertinoIcons.exclamationmark_circle_fill;
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
                  '可疑原因：',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ...suspiciousApp.reasons.map((reason) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Text(
                              reason,
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
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: riskColor,
                  borderRadius: BorderRadius.circular(8),
                  onPressed: () => _openAppSettings(app.packageName),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.settings, size: 16),
                      SizedBox(width: 6),
                      Text('查看详情', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SuspiciousApp {
  final AppInfo appInfo;
  final int riskScore;
  final List<String> reasons;

  SuspiciousApp({
    required this.appInfo,
    required this.riskScore,
    required this.reasons,
  });
}
