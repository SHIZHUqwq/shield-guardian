import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_sms/flutter_sms.dart';

class ContactsAlertScreen extends StatefulWidget {
  const ContactsAlertScreen({Key? key}) : super(key: key);

  @override
  State<ContactsAlertScreen> createState() => _ContactsAlertScreenState();
}

class _ContactsAlertScreenState extends State<ContactsAlertScreen> {
  List<Contact> _contacts = [];
  List<Contact> _selectedContacts = [];
  bool _isLoading = false;
  bool _selectAll = false;
  final TextEditingController _messageController = TextEditingController(
    text: '【安全警告】我的手机近期遭遇诈骗软件攻击，通讯录信息可能已泄露。'
        '如有人冒充我向您借钱或发送可疑链接，请勿相信！有事请直接打电话确认。',
  );

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    try {
      if (await Permission.contacts.request().isGranted) {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );
        setState(() {
          _contacts = contacts.where((c) => c.phones.isNotEmpty).toList();
          _isLoading = false;
        });
      } else {
        _showPermissionDeniedDialog();
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('加载联系人失败: $e');
    }
  }

  void _showPermissionDeniedDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('需要权限'),
        content: const Text('需要访问通讯录权限才能使用此功能，请在设置中允许'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('去设置'),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
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

  Future<void> _sendMessages() async {
    if (_selectedContacts.isEmpty) {
      _showErrorDialog('请先选择要通知的联系人');
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      _showErrorDialog('请输入要发送的消息');
      return;
    }

    // 检查短信权限
    if (!await Permission.sms.request().isGranted) {
      _showErrorDialog('需要短信权限才能发送消息');
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('确认发送'),
        content: Text('即将向${_selectedContacts.length}位联系人发送短信，是否继续？'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await _performSendMessages();
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }

  Future<void> _performSendMessages() async {
    setState(() => _isLoading = true);

    try {
      List<String> recipients = [];
      for (var contact in _selectedContacts) {
        if (contact.phones.isNotEmpty) {
          recipients.add(contact.phones.first.number);
        }
      }

      await sendSMS(
        message: _messageController.text,
        recipients: recipients,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('发送成功'),
            content: Text('已向${recipients.length}位联系人发送通知'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('发送失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('通知联系人'),
        backgroundColor: const Color(0xF0F9F9F9),
        trailing: _selectedContacts.isNotEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text('发送'),
                onPressed: _sendMessages,
              )
            : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildMessageEditor(),
            _buildSelectAllBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _buildContactsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageEditor() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '短信内容',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CupertinoTextField(
              controller: _messageController,
              placeholder: '输入要发送的短信内容',
              maxLines: 4,
              padding: const EdgeInsets.all(12),
              decoration: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectAllBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '已选择 ${_selectedContacts.length} / ${_contacts.length} 位联系人',
            style: const TextStyle(
              fontSize: 15,
              color: CupertinoColors.systemGrey,
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _selectAll = !_selectAll;
                if (_selectAll) {
                  _selectedContacts = List.from(_contacts);
                } else {
                  _selectedContacts.clear();
                }
              });
            },
            child: Text(_selectAll ? '取消全选' : '全选'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    if (_contacts.isEmpty) {
      return const Center(
        child: Text(
          '没有找到联系人',
          style: TextStyle(color: CupertinoColors.systemGrey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        final isSelected = _selectedContacts.contains(contact);

        return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            onPressed: () {
              setState(() {
                if (isSelected) {
                  _selectedContacts.remove(contact);
                } else {
                  _selectedContacts.add(contact);
                }
                _selectAll = _selectedContacts.length == _contacts.length;
              });
            },
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? CupertinoColors.systemBlue
                        : CupertinoColors.systemGrey5,
                  ),
                  child: isSelected
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
                      Text(
                        contact.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.black,
                        ),
                      ),
                      if (contact.phones.isNotEmpty)
                        Text(
                          contact.phones.first.number,
                          style: const TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
