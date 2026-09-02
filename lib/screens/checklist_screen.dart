import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      action: '拨打95588/95599等',
    ),
    ChecklistItem(
      title: '修改支付密码',
      description: '立即修改支付宝、微信支付、银行APP等所有支付密码',
      priority: 'critical',
      action: '打开各支付APP修改',
    ),
    ChecklistItem(
      title: '更改重要账户密码',
      description: '修改邮箱、社交账号、购物平台等重要账户的登录密码',
      priority: 'high',
      action: '逐个修改密码',
    ),
    ChecklistItem(
      title: '启用双因素认证',
      description: '在所有支持的平台上启用两步验证或双因素认证',
      priority: 'high',
      action: '在账户设置中启用',
    ),
    ChecklistItem(
      title: '检查个人征信',
      description: '登录中国人民银行征信中心，查看是否有异常贷款或信用卡开户',
      priority: 'high',
      action: '访问征信中心官网',
    ),
    ChecklistItem(
      title: '通知家人朋友',
      description: '告知通讯录联系人，防止诈骗者冒充你进行二次诈骗',
      priority: 'medium',
      action: '使用"通知联系人"功能',
    ),
    ChecklistItem(
      title: '卸载可疑应用',
      description: '卸载所有最近安装的陌生应用，特别是要求过多权限的应用',
      priority: 'medium',
      action: '进入系统设置卸载',
    ),
    ChecklistItem(
      title: '撤销应用权限',
      description: '检查并撤销所有不必要的应用权限，特别是通讯录、短信、位置等',
      priority: 'medium',
      action: '使用"权限监控"功能',
    ),
    ChecklistItem(
      title: '报警备案',
      description: '向当地公安机关报案，保留诈骗证据（聊天记录、转账记录等）',
      priority: 'low',
      action: '拨打110或前往派出所',
    ),
    ChecklistItem(
      title: '监控账户动态',
      description: '未来30天持续关注银行账户、征信报告的异常变动',
      priority: 'low',
      action: '设置余额变动提醒',
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

  @override
  Widget build(BuildContext context) {
    int completedCount = _checkedItems.values.where((v) => v).length;
    double progress = _items.isEmpty ? 0 : completedCount / _items.length;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('应急检查清单'),
        backgroundColor: Color(0xF0F9F9F9),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildProgressSection(completedCount, progress),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return _buildChecklistItem(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(int completedCount, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.systemGrey5,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '完成进度',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$completedCount / ${_items.length}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: CupertinoColors.systemGrey5,
              valueColor: const AlwaysStoppedAnimation<Color>(
                CupertinoColors.systemBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(int index) {
    final item = _items[index];
    final isChecked = _checkedItems[index] ?? false;

    Color priorityColor;
    String priorityText;
    switch (item.priority) {
      case 'critical':
        priorityColor = CupertinoColors.systemRed;
        priorityText = '紧急';
        break;
      case 'high':
        priorityColor = CupertinoColors.systemOrange;
        priorityText = '重要';
        break;
      case 'medium':
        priorityColor = CupertinoColors.systemBlue;
        priorityText = '建议';
        break;
      default:
        priorityColor = CupertinoColors.systemGrey;
        priorityText = '可选';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          setState(() {
            _checkedItems[index] = !isChecked;
            _saveCheckedStatus(index, _checkedItems[index]!);
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isChecked
                      ? CupertinoColors.systemBlue
                      : CupertinoColors.systemGrey5,
                ),
                child: isChecked
                    ? const Icon(
                        CupertinoIcons.check_mark,
                        size: 14,
                        color: CupertinoColors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            priorityText,
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isChecked
                                  ? CupertinoColors.systemGrey
                                  : CupertinoColors.black,
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.lightbulb_fill,
                          size: 14,
                          color: CupertinoColors.systemYellow,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.action,
                            style: const TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.systemBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChecklistItem {
  final String title;
  final String description;
  final String priority;
  final String action;

  ChecklistItem({
    required this.title,
    required this.description,
    required this.priority,
    required this.action,
  });
}
