import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PermissionMonitorScreen extends StatefulWidget {
  const PermissionMonitorScreen({Key? key}) : super(key: key);

  @override
  State<PermissionMonitorScreen> createState() => _PermissionMonitorScreenState();
}

class _PermissionMonitorScreenState extends State<PermissionMonitorScreen> {
  bool _isLoading = false;
  Map<String, PermissionStatus> _permissions = {};

  final List<PermissionInfo> _dangerousPermissions = [
    PermissionInfo(
      permission: Permission.contacts,
      name: '通讯录',
      icon: CupertinoIcons.person_2_fill,
      description: '访问您的联系人信息',
      riskLevel: 'high',
    ),
    PermissionInfo(
      permission: Permission.sms,
      name: '短信',
      icon: CupertinoIcons.chat_bubble_2_fill,
      description: '读取和发送短信',
      riskLevel: 'high',
    ),
    PermissionInfo(
      permission: Permission.phone,
      name: '电话',
      icon: CupertinoIcons.phone_fill,
      description: '拨打电话和访问通话记录',
      riskLevel: 'high',
    ),
    PermissionInfo(
      permission: Permission.location,
      name: '位置信息',
      icon: CupertinoIcons.location_fill,
      description: '访问您的地理位置',
      riskLevel: 'medium',
    ),
    PermissionInfo(
      permission: Permission.camera,
      name: '相机',
      icon: CupertinoIcons.camera_fill,
      description: '拍摄照片和视频',
      riskLevel: 'medium',
    ),
    PermissionInfo(
      permission: Permission.microphone,
      name: '麦克风',
      icon: CupertinoIcons.mic_fill,
      description: '录制音频',
      riskLevel: 'medium',
    ),
    PermissionInfo(
      permission: Permission.storage,
      name: '存储空间',
      icon: CupertinoIcons.folder_fill,
      description: '读取和写入文件',
      riskLevel: 'low',
    ),
    PermissionInfo(
      permission: Permission.calendar,
      name: '日历',
      icon: CupertinoIcons.calendar,
      description: '访问日历事件',
      riskLevel: 'low',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);

    Map<String, PermissionStatus> statuses = {};

    for (var permInfo in _dangerousPermissions) {
      try {
        statuses[permInfo.name] = await permInfo.permission.status;
      } catch (e) {
        statuses[permInfo.name] = PermissionStatus.denied;
      }
    }

    setState(() {
      _permissions = statuses;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    int grantedCount = _permissions.values
        .where((status) => status.isGranted)
        .length;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('权限监控'),
        backgroundColor: const Color(0xF0F9F9F9),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: _checkPermissions,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildSummaryCard(grantedCount),
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _buildPermissionsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int grantedCount) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (grantedCount == 0) {
      statusColor = CupertinoColors.systemGreen;
      statusText = '安全';
      statusIcon = CupertinoIcons.checkmark_shield_fill;
    } else if (grantedCount <= 2) {
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
            '权限状态: $statusText',
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '已授予 $grantedCount/${_dangerousPermissions.length} 项敏感权限',
            style: const TextStyle(
              color: Color(0xFFE5E5EA),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _dangerousPermissions.length,
      itemBuilder: (context, index) {
        final permInfo = _dangerousPermissions[index];
        final status = _permissions[permInfo.name] ?? PermissionStatus.denied;

        return _buildPermissionCard(permInfo, status);
      },
    );
  }

  Widget _buildPermissionCard(PermissionInfo permInfo, PermissionStatus status) {
    Color riskColor;
    String riskText;
    switch (permInfo.riskLevel) {
      case 'high':
        riskColor = CupertinoColors.systemRed;
        riskText = '高风险';
        break;
      case 'medium':
        riskColor = CupertinoColors.systemOrange;
        riskText = '中风险';
        break;
      default:
        riskColor = CupertinoColors.systemBlue;
        riskText = '低风险';
    }

    bool isGranted = status.isGranted;
    Color statusColor = isGranted
        ? CupertinoColors.systemRed
        : CupertinoColors.systemGreen;
    String statusText = isGranted ? '已授权' : '未授权';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted
              ? CupertinoColors.systemRed.withOpacity(0.3)
              : CupertinoColors.systemGrey5,
          width: 1,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  permInfo.icon,
                  color: riskColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          permInfo.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            riskText,
                            style: TextStyle(
                              color: riskColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      permInfo.description,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isGranted
                        ? CupertinoIcons.exclamationmark_circle_fill
                        : CupertinoIcons.checkmark_circle_fill,
                    color: statusColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (isGranted)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: CupertinoColors.systemRed,
                  borderRadius: BorderRadius.circular(8),
                  minSize: 0,
                  onPressed: () => openAppSettings(),
                  child: const Text(
                    '去撤销',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.white,
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

class PermissionInfo {
  final Permission permission;
  final String name;
  final IconData icon;
  final String description;
  final String riskLevel;

  PermissionInfo({
    required this.permission,
    required this.name,
    required this.icon,
    required this.description,
    required this.riskLevel,
  });
}
