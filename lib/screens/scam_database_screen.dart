import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ScamDatabaseScreen extends StatefulWidget {
  const ScamDatabaseScreen({Key? key}) : super(key: key);

  @override
  State<ScamDatabaseScreen> createState() => _ScamDatabaseScreenState();
}

class _ScamDatabaseScreenState extends State<ScamDatabaseScreen> {
  List<ScamApp> _scamApps = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadScamDatabase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadScamDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('scam_database');

    if (data != null) {
      final List<dynamic> jsonList = json.decode(data);
      setState(() {
        _scamApps = jsonList.map((json) => ScamApp.fromJson(json)).toList();
      });
    } else {
      // 预置一些示例数据
      _scamApps = [
        ScamApp(
          name: '快速贷款',
          packageName: 'com.fake.loan',
          description: '伪装成贷款应用，实际窃取通讯录和短信',
          reportCount: 156,
          riskLevel: 'critical',
          reportDate: DateTime.now().subtract(const Duration(days: 2)),
        ),
        ScamApp(
          name: '清理大师Pro',
          packageName: 'com.fake.cleaner',
          description: '要求过多权限，上传用户隐私数据',
          reportCount: 89,
          riskLevel: 'high',
          reportDate: DateTime.now().subtract(const Duration(days: 5)),
        ),
        ScamApp(
          name: '赚钱神器',
          packageName: 'com.fake.money',
          description: '诱导用户填写个人信息并授权敏感权限',
          reportCount: 234,
          riskLevel: 'critical',
          reportDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      await _saveDatabase();
    }
  }

  Future<void> _saveDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(_scamApps.map((app) => app.toJson()).toList());
    await prefs.setString('scam_database', data);
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final packageController = TextEditingController();
    final descController = TextEditingController();
    String selectedRisk = 'high';

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('提交诈骗应用'),
        content: Column(
          children: [
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: nameController,
              placeholder: '应用名称',
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: packageController,
              placeholder: '包名（可选）',
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: descController,
              placeholder: '诈骗方式描述',
              maxLines: 3,
              padding: const EdgeInsets.all(12),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  descController.text.isNotEmpty) {
                setState(() {
                  _scamApps.insert(
                    0,
                    ScamApp(
                      name: nameController.text,
                      packageName: packageController.text,
                      description: descController.text,
                      reportCount: 1,
                      riskLevel: selectedRisk,
                      reportDate: DateTime.now(),
                    ),
                  );
                });
                _saveDatabase();
                Navigator.pop(context);

                showCupertinoDialog(
                  context: context,
                  builder: (ctx) => CupertinoAlertDialog(
                    title: const Text('提交成功'),
                    content: const Text('感谢您的贡献，帮助更多人远离诈骗'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('确定'),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }

  List<ScamApp> get _filteredApps {
    if (_searchQuery.isEmpty) {
      return _scamApps;
    }
    return _scamApps.where((app) {
      return app.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app.packageName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('诈骗数据库'),
        backgroundColor: const Color(0xF0F9F9F9),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: _showAddDialog,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildStatsBar(),
            Expanded(
              child: _buildScamList(),
            ),
          ],
        ),
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
            icon: CupertinoIcons.exclamationmark_triangle_fill,
            label: '诈骗应用',
            value: '${_scamApps.length}',
            color: CupertinoColors.systemRed,
          ),
          _buildStatItem(
            icon: CupertinoIcons.flag_fill,
            label: '总举报数',
            value: '${_scamApps.fold<int>(0, (sum, app) => sum + app.reportCount)}',
            color: CupertinoColors.systemOrange,
          ),
          _buildStatItem(
            icon: CupertinoIcons.shield_fill,
            label: '已保护',
            value: '${_scamApps.fold<int>(0, (sum, app) => sum + app.reportCount) * 10}+',
            color: CupertinoColors.systemGreen,
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

  Widget _buildScamList() {
    final filteredApps = _filteredApps;

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
        return _buildScamCard(filteredApps[index]);
      },
    );
  }

  Widget _buildScamCard(ScamApp app) {
    Color riskColor;
    String riskText;
    IconData riskIcon;

    switch (app.riskLevel) {
      case 'critical':
        riskColor = CupertinoColors.systemRed;
        riskText = '极高危险';
        riskIcon = CupertinoIcons.xmark_octagon_fill;
        break;
      case 'high':
        riskColor = CupertinoColors.systemOrange;
        riskText = '高危险';
        riskIcon = CupertinoIcons.exclamationmark_triangle_fill;
        break;
      default:
        riskColor = CupertinoColors.systemYellow;
        riskText = '中危险';
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
                child: Icon(
                  riskIcon,
                  color: riskColor,
                  size: 28,
                ),
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
                    if (app.packageName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        app.packageName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
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
          Text(
            app.description,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.flag_fill,
                    size: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${app.reportCount} 次举报',
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    CupertinoIcons.clock_fill,
                    size: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(app.reportDate),
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今天';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}月${date.day}日';
    }
  }
}

class ScamApp {
  final String name;
  final String packageName;
  final String description;
  final int reportCount;
  final String riskLevel;
  final DateTime reportDate;

  ScamApp({
    required this.name,
    required this.packageName,
    required this.description,
    required this.reportCount,
    required this.riskLevel,
    required this.reportDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'packageName': packageName,
      'description': description,
      'reportCount': reportCount,
      'riskLevel': riskLevel,
      'reportDate': reportDate.toIso8601String(),
    };
  }

  factory ScamApp.fromJson(Map<String, dynamic> json) {
    return ScamApp(
      name: json['name'],
      packageName: json['packageName'],
      description: json['description'],
      reportCount: json['reportCount'],
      riskLevel: json['riskLevel'],
      reportDate: DateTime.parse(json['reportDate']),
    );
  }
}
