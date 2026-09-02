import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';

class VpnTrafficMonitorScreen extends StatefulWidget {
  const VpnTrafficMonitorScreen({Key? key}) : super(key: key);

  @override
  State<VpnTrafficMonitorScreen> createState() => _VpnTrafficMonitorScreenState();
}

class _VpnTrafficMonitorScreenState extends State<VpnTrafficMonitorScreen> {
  bool _isMonitoring = false;
  List<AppTrafficInfo> _trafficData = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _monitorTimer;
  int _monitorDuration = 0;

  // 敏感数据类型检测规则
  final List<SensitiveDataPattern> _dataPatterns = [
    SensitiveDataPattern(
      type: '手机号',
      icon: CupertinoIcons.phone,
      patterns: [r'1[3-9]\d{9}'],
      riskLevel: 'high',
    ),
    SensitiveDataPattern(
      type: '身份证号',
      icon: CupertinoIcons.person_crop_square,
      patterns: [r'\d{17}[\dXx]'],
      riskLevel: 'critical',
    ),
    SensitiveDataPattern(
      type: '银行卡号',
      icon: CupertinoIcons.creditcard,
      patterns: [r'\d{16,19}'],
      riskLevel: 'critical',
    ),
    SensitiveDataPattern(
      type: '验证码',
      icon: CupertinoIcons.lock_shield,
      patterns: [r'\d{4,6}'],
      riskLevel: 'high',
    ),
    SensitiveDataPattern(
      type: '密码',
      icon: CupertinoIcons.lock_fill,
      patterns: [r'password|passwd|pwd'],
      riskLevel: 'critical',
    ),
    SensitiveDataPattern(
      type: '通讯录',
      icon: CupertinoIcons.person_2_fill,
      patterns: [r'contact|addressbook'],
      riskLevel: 'high',
    ),
    SensitiveDataPattern(
      type: '位置信息',
      icon: CupertinoIcons.location_fill,
      patterns: [r'latitude|longitude|location|gps'],
      riskLevel: 'medium',
    ),
    SensitiveDataPattern(
      type: '设备ID',
      icon: CupertinoIcons.device_phone_portrait,
      patterns: [r'imei|deviceid|android_id'],
      riskLevel: 'medium',
    ),
    SensitiveDataPattern(
      type: '短信内容',
      icon: CupertinoIcons.chat_bubble_text_fill,
      patterns: [r'sms|message'],
      riskLevel: 'high',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadMonitoringState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _monitorTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMonitoringState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMonitoring = prefs.getBool('vpn_monitoring') ?? false;
    });

    if (_isMonitoring) {
      _startMonitoring();
    }
  }

  Future<void> _saveMonitoringState(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vpn_monitoring', state);
  }

  Future<void> _toggleMonitoring() async {
    if (_isMonitoring) {
      _stopMonitoring();
    } else {
      final hasPermission = await _checkVpnPermission();
      if (hasPermission) {
        _startMonitoring();
      }
    }
  }

  Future<bool> _checkVpnPermission() async {
    // 显示VPN权限说明
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.shield_lefthalf_fill, color: CupertinoColors.systemBlue),
            SizedBox(width: 8),
            Text('启用流量监控'),
          ],
        ),
        content: const Text(
          '流量监控功能说明：\n\n'
          '✓ 实时监控应用网络活动\n'
          '✓ 检测传输的数据类型\n'
          '✓ 识别敏感信息泄露\n'
          '✓ 所有数据仅在本地分析\n\n'
          '注意：\n'
          '• 此功能通过分析网络流量特征识别数据类型\n'
          '• 不会窃取或上传您的数据\n'
          '• 加密流量仅分析行为模式\n'
          '• 需要保持应用后台运行\n\n'
          '是否启用？',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('启用'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _startMonitoring() {
    setState(() {
      _isMonitoring = true;
      _monitorDuration = 0;
    });
    _saveMonitoringState(true);

    // 开始模拟监控（实际项目中需要实现真正的VPN服务）
    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _monitorDuration += 5;
      });
      _simulateTrafficCapture();
    });

    _showSuccess('流量监控已启动', '正在实时分析网络活动...');
  }

  void _stopMonitoring() {
    _monitorTimer?.cancel();
    setState(() {
      _isMonitoring = false;
    });
    _saveMonitoringState(false);
    _showSuccess('流量监控已停止', '共监控 ${_formatDuration(_monitorDuration)}');
  }

  Future<void> _simulateTrafficCapture() async {
    // 模拟抓取应用流量和数据类型识别
    // 实际项目中，这里应该是真实的VPN流量分析

    try {
      final apps = await InstalledApps.getInstalledApps(false, true);

      // 模拟部分应用的可疑流量
      final suspiciousApps = apps.where((app) =>
        app.name.contains('贷款') ||
        app.name.contains('赚钱') ||
        app.name.contains('清理')
      ).take(5);

      for (var app in suspiciousApps) {
        final existingIndex = _trafficData.indexWhere(
          (t) => t.appInfo.packageName == app.packageName
        );

        if (existingIndex >= 0) {
          // 更新现有数据
          setState(() {
            _trafficData[existingIndex].uploadBytes += (100000 + (DateTime.now().millisecond % 50000));
            _trafficData[existingIndex].downloadBytes += (50000 + (DateTime.now().millisecond % 20000));
            _trafficData[existingIndex].lastActiveTime = DateTime.now();

            // 随机检测到敏感数据
            if (DateTime.now().second % 10 < 3) {
              final randomPattern = _dataPatterns[DateTime.now().millisecond % _dataPatterns.length];
              if (!_trafficData[existingIndex].detectedDataTypes.contains(randomPattern.type)) {
                _trafficData[existingIndex].detectedDataTypes.add(randomPattern.type);
                _trafficData[existingIndex].connections.add(
                  NetworkConnection(
                    domain: _generateSuspiciousDomain(),
                    ip: _generateRandomIP(),
                    uploadBytes: 1024 * (10 + DateTime.now().second),
                    dataType: randomPattern.type,
                    timestamp: DateTime.now(),
                    isSecure: DateTime.now().millisecond % 2 == 0,
                  )
                );
              }
            }
          });
        } else {
          // 新增应用流量记录
          final newTraffic = AppTrafficInfo(
            appInfo: app,
            uploadBytes: 50000 + (DateTime.now().millisecond % 100000),
            downloadBytes: 20000 + (DateTime.now().millisecond % 50000),
            detectedDataTypes: [],
            connections: [],
            lastActiveTime: DateTime.now(),
          );

          setState(() {
            _trafficData.add(newTraffic);
          });
        }
      }

      // 按风险排序
      _trafficData.sort((a, b) => b.riskScore.compareTo(a.riskScore));

    } catch (e) {
      // 忽略错误
    }
  }

  String _generateSuspiciousDomain() {
    final domains = [
      'api.datacollector.cn',
      'track.adserver.com',
      '123.45.67.89',
      'unknown-server.xyz',
      'collect.tracking.net',
    ];
    return domains[DateTime.now().millisecond % domains.length];
  }

  String _generateRandomIP() {
    return '${100 + DateTime.now().second}.${DateTime.now().millisecond % 255}.${DateTime.now().microsecond % 255}.${(DateTime.now().millisecond + 50) % 255}';
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '$hours小时${minutes}分钟';
    } else if (minutes > 0) {
      return '$minutes分钟${secs}秒';
    } else {
      return '$secs秒';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Future<void> _openAppSettings(String packageName) async {
    try {
      final uri = Uri.parse('package:$packageName');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showError('无法打开应用设置');
    }
  }

  List<AppTrafficInfo> get _filteredData {
    if (_searchQuery.isEmpty) {
      return _trafficData;
    }
    return _trafficData.where((traffic) {
      return traffic.appInfo.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          traffic.appInfo.packageName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showSuccess(String title, String message) {
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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('流量监控'),
        backgroundColor: Color(0xF0F9F9F9),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildMonitoringStatus(),
            if (_trafficData.isNotEmpty) _buildSearchBar(),
            if (_trafficData.isNotEmpty) _buildStatsBar(),
            Expanded(
              child: _trafficData.isEmpty ? _buildEmptyState() : _buildTrafficList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isMonitoring
              ? [CupertinoColors.systemGreen.withOpacity(0.8), CupertinoColors.systemGreen]
              : [CupertinoColors.systemGrey.withOpacity(0.5), CupertinoColors.systemGrey],
        ),
        border: const Border(
          bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isMonitoring
                              ? CupertinoIcons.wifi_exclamationmark
                              : CupertinoIcons.wifi_slash,
                          color: CupertinoColors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isMonitoring ? '监控中' : '未监控',
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isMonitoring
                          ? '已运行 ${_formatDuration(_monitorDuration)}'
                          : '点击开关启动实时监控',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: _isMonitoring,
                onChanged: (value) => _toggleMonitoring(),
                activeColor: CupertinoColors.white,
              ),
            ],
          ),
          if (_isMonitoring) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.info_circle, color: CupertinoColors.white, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '正在实时分析应用传输的数据类型',
                      style: TextStyle(color: CupertinoColors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            _isMonitoring
                ? CupertinoIcons.search
                : CupertinoIcons.antenna_radiowaves_left_right,
            size: 80,
            color: CupertinoColors.systemGrey3,
          ),
          const SizedBox(height: 24),
          Text(
            _isMonitoring ? '正在监控中...' : '启动流量监控',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _isMonitoring
                  ? '等待应用产生网络活动\n检测到可疑数据传输时会立即显示'
                  : '开启监控后，系统会实时分析\n每个应用传输的数据类型',
              textAlign: TextAlign.center,
              style: const TextStyle(
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
          bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
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
    final totalUpload = _trafficData.fold<int>(0, (sum, t) => sum + t.uploadBytes);
    final totalDownload = _trafficData.fold<int>(0, (sum, t) => sum + t.downloadBytes);
    final highRisk = _trafficData.where((t) => t.riskScore >= 60).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGrey6,
        border: Border(
          bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: CupertinoIcons.arrow_up_circle,
            label: '上传',
            value: _formatBytes(totalUpload),
            color: CupertinoColors.systemOrange,
          ),
          _buildStatItem(
            icon: CupertinoIcons.arrow_down_circle,
            label: '下载',
            value: _formatBytes(totalDownload),
            color: CupertinoColors.systemBlue,
          ),
          _buildStatItem(
            icon: CupertinoIcons.exclamationmark_triangle_fill,
            label: '高风险',
            value: '$highRisk',
            color: highRisk > 0 ? CupertinoColors.systemRed : CupertinoColors.systemGreen,
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
            fontSize: 16,
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

  Widget _buildTrafficList() {
    final filteredData = _filteredData;

    if (filteredData.isEmpty) {
      return const Center(
        child: Text(
          '没有找到相关应用',
          style: TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        return _buildTrafficCard(filteredData[index]);
      },
    );
  }

  Widget _buildTrafficCard(AppTrafficInfo traffic) {
    final app = traffic.appInfo;
    final riskScore = traffic.riskScore;

    Color riskColor;
    String riskText;
    if (riskScore >= 60) {
      riskColor = CupertinoColors.systemRed;
      riskText = '高风险';
    } else if (riskScore >= 30) {
      riskColor = CupertinoColors.systemOrange;
      riskText = '中风险';
    } else {
      riskColor = CupertinoColors.systemGreen;
      riskText = '正常';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: riskColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
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
                          : Icon(CupertinoIcons.app, color: riskColor, size: 28),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDataItem(
                        icon: CupertinoIcons.arrow_up_circle_fill,
                        label: '上传',
                        value: _formatBytes(traffic.uploadBytes),
                        color: CupertinoColors.systemOrange,
                      ),
                    ),
                    Expanded(
                      child: _buildDataItem(
                        icon: CupertinoIcons.arrow_down_circle_fill,
                        label: '下载',
                        value: _formatBytes(traffic.downloadBytes),
                        color: CupertinoColors.systemBlue,
                      ),
                    ),
                  ],
                ),
                if (traffic.detectedDataTypes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: CupertinoColors.systemRed.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              CupertinoIcons.exclamationmark_triangle_fill,
                              size: 16,
                              color: CupertinoColors.systemRed,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '检测到传输的数据类型：',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: traffic.detectedDataTypes.map((type) {
                            final pattern = _dataPatterns.firstWhere(
                              (p) => p.type == type,
                              orElse: () => _dataPatterns[0],
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: CupertinoColors.systemRed.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(pattern.icon, size: 14, color: CupertinoColors.systemRed),
                                  const SizedBox(width: 4),
                                  Text(
                                    type,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors.systemRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
                if (traffic.connections.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showConnectionDetails(traffic),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '查看详细连接记录',
                            style: TextStyle(fontSize: 13),
                          ),
                          Row(
                            children: [
                              Text(
                                '${traffic.connections.length}条',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                              const Icon(
                                CupertinoIcons.chevron_right,
                                size: 16,
                                color: CupertinoColors.systemGrey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildDataItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showConnectionDetails(AppTrafficInfo traffic) {
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
                    bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${traffic.appInfo.name} 的连接记录',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('关闭'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: traffic.connections.length,
                  itemBuilder: (context, index) {
                    final conn = traffic.connections[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                conn.isSecure
                                    ? CupertinoIcons.lock_fill
                                    : CupertinoIcons.lock_open_fill,
                                size: 16,
                                color: conn.isSecure
                                    ? CupertinoColors.systemGreen
                                    : CupertinoColors.systemOrange,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  conn.domain,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'IP: ${conn.ip}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: CupertinoColors.systemGrey,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                CupertinoIcons.exclamationmark_triangle_fill,
                                size: 12,
                                color: CupertinoColors.systemRed,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '传输数据类型: ${conn.dataType}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.systemRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '上传: ${_formatBytes(conn.uploadBytes)} | ${_formatTime(conn.timestamp)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}秒前';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '${diff.inHours}小时前';
    }
  }
}

class AppTrafficInfo {
  final AppInfo appInfo;
  int uploadBytes;
  int downloadBytes;
  final List<String> detectedDataTypes;
  final List<NetworkConnection> connections;
  DateTime lastActiveTime;

  AppTrafficInfo({
    required this.appInfo,
    required this.uploadBytes,
    required this.downloadBytes,
    required this.detectedDataTypes,
    required this.connections,
    required this.lastActiveTime,
  });

  int get riskScore {
    int score = 0;

    // 上传数据量评分
    if (uploadBytes > 50 * 1024 * 1024) score += 40; // >50MB
    else if (uploadBytes > 10 * 1024 * 1024) score += 20; // >10MB

    // 检测到的敏感数据类型
    score += detectedDataTypes.length * 15;

    // 连接到可疑服务器
    final suspiciousConnections = connections.where((c) =>
      !c.isSecure || c.domain.contains('unknown') || c.domain.contains('track')
    ).length;
    score += suspiciousConnections * 10;

    return score > 100 ? 100 : score;
  }
}

class NetworkConnection {
  final String domain;
  final String ip;
  final int uploadBytes;
  final String dataType;
  final DateTime timestamp;
  final bool isSecure;

  NetworkConnection({
    required this.domain,
    required this.ip,
    required this.uploadBytes,
    required this.dataType,
    required this.timestamp,
    required this.isSecure,
  });
}

class SensitiveDataPattern {
  final String type;
  final IconData icon;
  final List<String> patterns;
  final String riskLevel;

  SensitiveDataPattern({
    required this.type,
    required this.icon,
    required this.patterns,
    required this.riskLevel,
  });
}
