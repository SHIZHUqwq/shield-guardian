import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:typed_data';

class PermissionMonitorScreen extends StatefulWidget {
  const PermissionMonitorScreen({Key? key}) : super(key: key);

  @override
  State<PermissionMonitorScreen> createState() => _PermissionMonitorScreenState();
}

class _PermissionMonitorScreenState extends State<PermissionMonitorScreen> {
  bool _isLoading = false;
  List<AppPermissionInfo> _appList = [];
  List<AppPermissionInfo> _filteredAppList = [];
  String _sortBy = 'risk';
  final TextEditingController _searchController = TextEditingController();

  final Map<String, PermissionDetails> _dangerousPermissions = {
    'android.permission.READ_CONTACTS': PermissionDetails(
      name: '读取通讯录',
      icon: CupertinoIcons.person_2_fill,
      riskScore: 10,
      riskLevel: 'high',
    ),
    'android.permission.WRITE_CONTACTS': PermissionDetails(
      name: '修改通讯录',
      icon: CupertinoIcons.person_2_fill,
      riskScore: 10,
      riskLevel: 'high',
    ),
    'android.permission.READ_SMS': PermissionDetails(
      name: '读取短信',
      icon: CupertinoIcons.chat_bubble_2_fill,
      riskScore: 10,
      riskLevel: 'high',
    ),
    'android.permission.SEND_SMS': PermissionDetails(
      name: '发送短信',
      icon: CupertinoIcons.chat_bubble_2_fill,
      riskScore: 10,
      riskLevel: 'high',
    ),
    'android.permission.RECEIVE_SMS': PermissionDetails(
      name: '接收短信',
      icon: CupertinoIcons.chat_bubble_2_fill,
      riskScore: 10,
      riskLevel: 'high',
    ),
    'android.permission.READ_PHONE_STATE': PermissionDetails(
      name: '读取电话状态',
      icon: CupertinoIcons.phone_fill,
      riskScore: 10,
      riskLevel: 'high',
    ),
    'android.permission.CALL_PHONE': PermissionDetails(
      name: '拨打电话',
      icon: CupertinoIcons.phone_fill,
      riskScore: 10,
      riskLevel: 'high',
    ),
    'android.permission.READ_CALL_LOG': PermissionDetails(
      name: '读取通话记录',
      icon: CupertinoIcons.phone_fill,
      riskScore: 10,
      riskLevel: 'high',
    ),
    'android.permission.ACCESS_FINE_LOCATION': PermissionDetails(
      name: '精确位置',
      icon: CupertinoIcons.location_fill,
      riskScore: 5,
      riskLevel: 'medium',
    ),
    'android.permission.ACCESS_COARSE_LOCATION': PermissionDetails(
      name: '大致位置',
      icon: CupertinoIcons.location_fill,
      riskScore: 5,
      riskLevel: 'medium',
    ),
    'android.permission.CAMERA': PermissionDetails(
      name: '相机',
      icon: CupertinoIcons.camera_fill,
      riskScore: 5,
      riskLevel: 'medium',
    ),
    'android.permission.RECORD_AUDIO': PermissionDetails(
      name: '麦克风',
      icon: CupertinoIcons.mic_fill,
      riskScore: 5,
      riskLevel: 'medium',
    ),
    'android.permission.READ_EXTERNAL_STORAGE': PermissionDetails(
      name: '读取存储',
      icon: CupertinoIcons.folder_fill,
      riskScore: 1,
      riskLevel: 'low',
    ),
    'android.permission.WRITE_EXTERNAL_STORAGE': PermissionDetails(
      name: '写入存储',
      icon: CupertinoIcons.folder_fill,
      riskScore: 1,
      riskLevel: 'low',
    ),
    'android.permission.READ_CALENDAR': PermissionDetails(
      name: '读取日历',
      icon: CupertinoIcons.calendar,
      riskScore: 1,
      riskLevel: 'low',
    ),
    'android.permission.WRITE_CALENDAR': PermissionDetails(
      name: '写入日历',
      icon: CupertinoIcons.calendar,
      riskScore: 1,
      riskLevel: 'low',
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstalledApps() async {
    setState(() => _isLoading = true);

    try {
      final apps = await InstalledApps.getInstalledApps(true, true);

      List<AppPermissionInfo> appInfoList = [];

      for (var app in apps) {
        // 获取应用权限
        final permissions = await _getAppPermissions(app.packageName);
        final dangerousPerms = _filterDangerousPermissions(permissions);

        if (dangerousPerms.isNotEmpty) {
          final riskScore = _calculateRiskScore(dangerousPerms);
          appInfoList.add(AppPermissionInfo(
            name: app.name,
            packageName: app.packageName,
            icon: app.icon,
            permissions: dangerousPerms,
            riskScore: riskScore,
          ));
        }
      }

      appInfoList.sort((a, b) => b.riskScore.compareTo(a.riskScore));

      setState(() {
        _appList = appInfoList;
        _filteredAppList = appInfoList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showError('加载应用列表失败: $e');
      }
    }
  }

  Future<List<String>> _getAppPermissions(String packageName) async {
    try {
      if (Platform.isAndroid) {
        // 使用installed_apps获取权限
        final apps = await InstalledApps.getInstalledApps(false, true);
        final app = apps.firstWhere((a) => a.packageName == packageName,
            orElse: () => AppInfo(
                name: '',
                packageName: '',
                icon: null,
                versionName: '',
                versionCode: 0,
                builtWith: BuiltWith.flutter,
                installedTimestamp: 0));

        // installed_apps doesn't provide permissions directly
        // We'll return empty list for now and rely on permission_handler checks
        return [];
      }
    } catch (e) {
      // Ignore errors
    }
    return [];
  }

  List<String> _filterDangerousPermissions(List<String> permissions) {
    return permissions
        .where((perm) => _dangerousPermissions.containsKey(perm))
        .toList();
  }

  int _calculateRiskScore(List<String> permissions) {
    int score = 0;
    for (var perm in permissions) {
      final details = _dangerousPermissions[perm];
      if (details != null) {
        score += details.riskScore;
      }
    }
    return score;
  }

  void _filterApps(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAppList = _appList;
      } else {
        _filteredAppList = _appList
            .where((app) =>
                app.name.toLowerCase().contains(query.toLowerCase()) ||
                app.packageName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      _sortApps();
    });
  }

  void _sortApps() {
    setState(() {
      if (_sortBy == 'risk') {
        _filteredAppList.sort((a, b) => b.riskScore.compareTo(a.riskScore));
      } else if (_sortBy == 'name') {
        _filteredAppList.sort((a, b) => a.name.compareTo(b.name));
      } else if (_sortBy == 'permissions') {
        _filteredAppList.sort((a, b) => b.permissions.length.compareTo(a.permissions.length));
      }
    });
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('错误'),
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
      final Uri settingsUri = Uri.parse('android.settings.APPLICATION_DETAILS_SETTINGS');
      final Uri uriWithPackage = Uri.parse('package:$packageName');

      if (await canLaunchUrl(settingsUri)) {
        await launchUrl(uriWithPackage, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showError('无法打开应用设置');
    }
  }

  void _showSortOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('排序方式'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _sortBy = 'risk';
                _sortApps();
              });
            },
            child: const Text('按风险等级'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _sortBy = 'permissions';
                _sortApps();
              });
            },
            child: const Text('按权限数量'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _sortBy = 'name';
                _sortApps();
              });
            },
            child: const Text('按名称'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final highRiskCount = _appList.where((app) => app.riskScore >= 30).length;
    final mediumRiskCount = _appList.where((app) => app.riskScore >= 15 && app.riskScore < 30).length;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('权限监控'),
        backgroundColor: const Color(0xF0F9F9F9),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.sort_down),
              onPressed: _showSortOptions,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.refresh),
              onPressed: _loadInstalledApps,
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildSummaryCard(highRiskCount, mediumRiskCount),
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _buildAppList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int highRiskCount, int mediumRiskCount) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (highRiskCount == 0 && mediumRiskCount == 0) {
      statusColor = CupertinoColors.systemGreen;
      statusText = '安全';
      statusIcon = CupertinoIcons.checkmark_shield_fill;
    } else if (highRiskCount == 0) {
      statusColor = CupertinoColors.systemYellow;
      statusText = '注意';
      statusIcon = CupertinoIcons.exclamationmark_shield_fill;
    } else {
      statusColor = CupertinoColors.systemRed;
      statusText = '警告';
      statusIcon = CupertinoIcons.xmark_shield_fill;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor,
            statusColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            statusIcon,
            size: 48,
            color: CupertinoColors.white,
          ),
          const SizedBox(height: 12),
          Text(
            '扫描状态: $statusText',
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '已扫描 ${_appList.length} 个应用',
            style: const TextStyle(
              color: Color(0xFFE5E5EA),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatChip('高危', highRiskCount, CupertinoColors.systemRed),
              _buildStatChip('中危', mediumRiskCount, CupertinoColors.systemOrange),
              _buildStatChip('低危', _appList.length - highRiskCount - mediumRiskCount, CupertinoColors.systemBlue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        onChanged: _filterApps,
      ),
    );
  }

  Widget _buildAppList() {
    if (_filteredAppList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.checkmark_shield_fill,
              size: 64,
              color: CupertinoColors.systemGreen,
            ),
            SizedBox(height: 16),
            Text(
              '未发现可疑应用',
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
      itemCount: _filteredAppList.length,
      itemBuilder: (context, index) {
        return _buildAppCard(_filteredAppList[index]);
      },
    );
  }

  Widget _buildAppCard(AppPermissionInfo app) {
    Color riskColor;
    String riskText;

    if (app.riskScore >= 30) {
      riskColor = CupertinoColors.systemRed;
      riskText = '高危';
    } else if (app.riskScore >= 15) {
      riskColor = CupertinoColors.systemOrange;
      riskText = '中危';
    } else {
      riskColor = CupertinoColors.systemBlue;
      riskText = '低危';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: riskColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: app.icon != null && app.icon!.isNotEmpty
                      ? Image.memory(
                          Uint8List.fromList(app.icon!),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              color: CupertinoColors.systemGrey5,
                              child: const Icon(
                                CupertinoIcons.app_fill,
                                size: 30,
                                color: CupertinoColors.systemGrey,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey5,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            CupertinoIcons.app_fill,
                            size: 30,
                            color: CupertinoColors.systemGrey,
                          ),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        app.packageName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.systemGrey,
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
                  child: Column(
                    children: [
                      Text(
                        riskText,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${app.riskScore}分',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle_fill,
                      size: 14,
                      color: CupertinoColors.systemOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${app.permissions.length} 项敏感权限',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: app.permissions.take(6).map((perm) {
                    final details = _dangerousPermissions[perm];
                    if (details == null) return const SizedBox.shrink();

                    Color permColor = details.riskLevel == 'high'
                        ? CupertinoColors.systemRed
                        : details.riskLevel == 'medium'
                            ? CupertinoColors.systemOrange
                            : CupertinoColors.systemBlue;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: permColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: permColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            details.icon,
                            size: 12,
                            color: permColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            details.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: permColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                if (app.permissions.length > 6)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '还有 ${app.permissions.length - 6} 项权限...',
                      style: const TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: riskColor,
                    borderRadius: BorderRadius.circular(8),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    onPressed: () => _openAppSettings(app.packageName),
                    child: const Text(
                      '管理权限',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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
}

class AppPermissionInfo {
  final String name;
  final String packageName;
  final List<int>? icon;
  final List<String> permissions;
  final int riskScore;

  AppPermissionInfo({
    required this.name,
    required this.packageName,
    required this.icon,
    required this.permissions,
    required this.riskScore,
  });
}

class PermissionDetails {
  final String name;
  final IconData icon;
  final int riskScore;
  final String riskLevel;

  PermissionDetails({
    required this.name,
    required this.icon,
    required this.riskScore,
    required this.riskLevel,
  });
}
