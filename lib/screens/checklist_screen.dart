import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:installed_apps/installed_apps.dart';
import 'contacts_alert_screen.dart';
import 'permission_monitor_screen.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({Key? key}) : super(key: key);

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final List<ChecklistItem> _items = [
    ChecklistItem(
      title: '立即冻结所有银行卡',
      description: '拨打银行客服电话，临时冻结所有银行卡，防止资金被盗',
      priority: 'critical',
      actionType: ChecklistActionType.bankCall,
      actionData: {
        'banks': [
          {'name': '工商银行', 'phone': '95588'},
          {'name': '建设银行', 'phone': '95533'},
          {'name': '农业银行', 'phone': '95599'},
          {'name': '中国银行', 'phone': '95566'},
          {'name': '交通银行', 'phone': '95559'},
          {'name': '招商银行', 'phone': '95555'},
          {'name': '邮储银行', 'phone': '95580'},
        ],
      },
    ),
    ChecklistItem(
      title: '修改支付密码',
      description: '立即修改支付宝、微信支付、银行APP等所有支付密码',
      priority: 'critical',
      actionType: ChecklistActionType.openApp,
      actionData: {
        'apps': [
          {'name': '支付宝', 'package': 'com.eg.android.AlipayGphone'},
          {'name': '微信', 'package': 'com.tencent.mm'},
        ],
      },
    ),
    ChecklistItem(
      title: '更改重要账户密码',
      description: '修改邮箱、社交账号、购物平台等重要账户的登录密码',
      priority: 'high',
      actionType: ChecklistActionType.openUrl,
      actionData: {
        'urls': [
          {'name': '淘宝/支付宝', 'url': 'https://accounts.alipay.com'},
          {'name': '京东', 'url': 'https://passport.jd.com'},
        ],
      },
    ),
    ChecklistItem(
      title: '检查个人征信',
      description: '登录中国人民银行征信中心，查看是否有异常贷款或信用卡开户',
      priority: 'high',
      actionType: ChecklistActionType.openUrl,
      actionData: {
        'urls': [
          {'name': '征信中心', 'url': 'https://ipcrs.pbccrc.org.cn'},
        ],
      },
    ),
    ChecklistItem(
      title: '通知家人朋友',
      description: '告知通讯录联系人，防止诈骗者冒充你进行二次诈骗',
      priority: 'medium',
      actionType: ChecklistActionType.navigateScreen,
      actionData: {'screen': 'contacts'},
    ),
    ChecklistItem(
      title: '撤销应用权限',
      description: '检查并撤销所有不必要的应用权限，特别是通讯录、短信、位置等',
      priority: 'medium',
      actionType: ChecklistActionType.navigateScreen,
      actionData: {'screen': 'permissions'},
    ),
    ChecklistItem(
      title: '报警备案',
      description: '向当地公安机关报案，保留诈骗证据（聊天记录、转账记录等）',
      priority: 'low',
      actionType: ChecklistActionType.call,
      actionData: {'phone': '110'},
    ),
    ChecklistItem(
      title: '监控账户动态',
      description: '未来30天持续关注银行账户、征信报告的异常变动',
      priority: 'low',
      actionType: ChecklistActionType.none,
      actionData: {},
    ),
  ];

  Map<int, bool> _checkedItems = {};

  @override
  void initState() {
    super.initState();
    _loadCheckedStatus();
  }

  Future<void> _loadCheckedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int i = 0; i < _items.length; i++) {
        _checkedItems[i] = prefs.getBool('checklist_$i') ?? false;
      }
    });
  }

  Future<void> _saveCheckedStatus(int index, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('checklist_$index', value);
  }

  Future<void> _executeAction(ChecklistItem item) async {
    switch (item.actionType) {
      case ChecklistActionType.bankCall:
        await _showBankSelection(item.actionData['banks'] as List);
        break;
      case ChecklistActionType.call:
        await _makeCall(item.actionData['phone'] as String);
        break;
      case ChecklistActionType.openApp:
        await _showAppSelection(item.actionData['apps'] as List);
        break;
      case ChecklistActionType.openUrl:
        await _showUrlSelection(item.actionData['urls'] as List);
        break;
      case ChecklistActionType.navigateScreen:
        await _navigateToScreen(item.actionData['screen'] as String);
        break;
      case ChecklistActionType.none:
        break;
    }
  }

  Future<void> _showBankSelection(List banks) async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('选择银行'),
        message: const Text('拨打银行客服电话冻结银行卡'),
        actions: banks.map((bank) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _makeCall(bank['phone'] as String);
            },
            child: Text('${bank['name']} - ${bank['phone']}'),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError('无法拨打电话');
    }
  }

  Future<void> _showAppSelection(List apps) async {
    // 检测应用是否已安装
    List<Map<String, dynamic>> installedApps = [];
    List<String> notInstalledApps = [];

    try {
      final allApps = await InstalledApps.getInstalledApps(false, true);
      final packageNames = allApps.map((a) => a.packageName).toSet();

      for (var app in apps) {
        if (packageNames.contains(app['package'])) {
          installedApps.add({
            'name': app['name'],
            'package': app['package'],
            'installed': true,
          });
        } else {
          notInstalledApps.add(app['name'] as String);
        }
      }
    } catch (e) {
      _showError('检测应用失败: $e');
      return;
    }

    if (!mounted) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('选择应用'),
        message: Text(
          installedApps.isEmpty
              ? '未检测到支付应用，请手动打开修改密码'
              : '打开应用修改密码',
        ),
        actions: [
          ...installedApps.map((app) {
            return CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _openApp(app['package'] as String, app['name'] as String);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(app['name'] as String),
                  const SizedBox(width: 8),
                  const Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    color: CupertinoColors.systemGreen,
                    size: 18,
                  ),
                ],
              ),
            );
          }),
          ...notInstalledApps.map((appName) {
            return CupertinoActionSheetAction(
              onPressed: null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    appName,
                    style: const TextStyle(color: CupertinoColors.systemGrey),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '(未安装)',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Future<void> _openApp(String packageName, String appName) async {
    try {
      final uri = Uri.parse('package:$packageName');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showError('无法打开$appName');
    }
  }

  Future<void> _showUrlSelection(List urls) async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('选择网站'),
        actions: urls.map((url) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _openUrl(url['url'] as String);
            },
            child: Text(url['name'] as String),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('无法打开网页');
    }
  }

  Future<void> _navigateToScreen(String screen) async {
    Widget? targetScreen;
    switch (screen) {
      case 'contacts':
        targetScreen = const ContactsAlertScreen();
        break;
      case 'permissions':
        targetScreen = const PermissionMonitorScreen();
        break;
    }

    if (targetScreen != null && mounted) {
      await Navigator.push(
        context,
        CupertinoPageRoute(builder: (context) => targetScreen!),
      );
    }
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
    final completedCount = _checkedItems.values.where((v) => v).length;
    final progress = _items.isEmpty ? 0.0 : completedCount / _items.length;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: const Color(0xFFF2F2F7),
            border: null,
            largeTitle: const Text(
              '应急检查清单',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            trailing: Text(
              '$completedCount/${_items.length}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _buildProgressCard(progress, completedCount),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildChecklistItem(_items[index], index),
                childCount: _items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(double progress, int completedCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: progress == 1.0
              ? [const Color(0xFF34C759), const Color(0xFF5DD57C)]
              : [const Color(0xFF007AFF), const Color(0xFF5856D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (progress == 1.0
                    ? const Color(0xFF34C759)
                    : const Color(0xFF007AFF))
                .withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  progress == 1.0
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.list_bullet_below_rectangle,
                  color: CupertinoColors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  progress == 1.0 ? '全部完成！' : '应急响应进度',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: CupertinoColors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                CupertinoColors.white,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            progress == 1.0
                ? '太棒了！您已完成所有关键步骤'
                : '还有 ${_items.length - completedCount} 项待完成',
            style: TextStyle(
              color: CupertinoColors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(ChecklistItem item, int index) {
    final isChecked = _checkedItems[index] ?? false;
    Color priorityColor;
    IconData priorityIcon;
    String priorityLabel;

    switch (item.priority) {
      case 'critical':
        priorityColor = CupertinoColors.systemRed;
        priorityIcon = CupertinoIcons.flame_fill;
        priorityLabel = '紧急';
        break;
      case 'high':
        priorityColor = CupertinoColors.systemOrange;
        priorityIcon = CupertinoIcons.exclamationmark_triangle_fill;
        priorityLabel = '重要';
        break;
      case 'medium':
        priorityColor = CupertinoColors.systemYellow;
        priorityIcon = CupertinoIcons.info_circle_fill;
        priorityLabel = '中等';
        break;
      default:
        priorityColor = CupertinoColors.systemGrey;
        priorityIcon = CupertinoIcons.circle_fill;
        priorityLabel = '一般';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isChecked
                ? CupertinoColors.systemGreen.withOpacity(0.15)
                : CupertinoColors.systemGrey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isChecked ? CupertinoColors.systemGreen : priorityColor,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isChecked
                            ? CupertinoColors.systemGreen.withOpacity(0.15)
                            : priorityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isChecked ? CupertinoIcons.check_mark_circle_fill : priorityIcon,
                        color: isChecked ? CupertinoColors.systemGreen : priorityColor,
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
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: isChecked
                                        ? CupertinoColors.systemGrey
                                        : CupertinoColors.black,
                                    decoration: isChecked
                                        ? TextDecoration.lineThrough
                                        : null,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              if (!isChecked)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: priorityColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    priorityLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: priorityColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: isChecked
                                  ? CupertinoColors.systemGrey2
                                  : CupertinoColors.systemGrey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Transform.scale(
                      scale: 0.85,
                      child: CupertinoSwitch(
                        value: isChecked,
                        activeColor: CupertinoColors.systemGreen,
                        onChanged: (value) {
                          setState(() {
                            _checkedItems[index] = value;
                          });
                          _saveCheckedStatus(index, value);
                        },
                      ),
                    ),
                  ],
                ),
                if (item.actionType != ChecklistActionType.none && !isChecked)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: priorityColor,
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () => _executeAction(item),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.arrow_right_circle_fill,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '立即操作',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum ChecklistActionType {
  bankCall,
  call,
  openApp,
  openUrl,
  navigateScreen,
  none,
}

class ChecklistItem {
  final String title;
  final String description;
  final String priority;
  final ChecklistActionType actionType;
  final Map<String, dynamic> actionData;

  ChecklistItem({
    required this.title,
    required this.description,
    required this.priority,
    required this.actionType,
    required this.actionData,
  });
}
