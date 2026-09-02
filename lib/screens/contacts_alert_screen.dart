import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';

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

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('发送方式'),
        content: const Text('将打开短信应用，您可以在那里编辑并发送消息给选中的联系人。'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await _performSendMessages();
            },
            child: const Text('打开短信'),
          ),
        ],
      ),
    );
  }

  Future<void> _performSendMessages() async {
    try {
      List<String> phoneNumbers = [];
      for (var contact in _selectedContacts) {
        if (contact.phones.isNotEmpty) {
          phoneNumbers.add(contact.phones.first.number);
        }
      }

      if (phoneNumbers.isEmpty) {
        _showErrorDialog('所选联系人没有电话号码');
        return;
      }

      final String recipients = phoneNumbers.join(',');
      final String message = Uri.encodeComponent(_messageController.text);
      final Uri smsUri = Uri.parse('sms:$recipients?body=$message');

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);

        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('提示'),
              content: Text('已打开短信应用，准备向${phoneNumbers.length}位联系人发送通知'),
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
      } else {
        _showErrorDialog('无法打开短信应用');
      }
    } catch (e) {
      _showErrorDialog('操作失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: const Color(0xFFF2F2F7),
            border: null,
            largeTitle: const Text(
              '通知联系人',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            trailing: _selectedContacts.isNotEmpty
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text(
                      '发送',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    onPressed: _sendMessages,
                  )
                : null,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildMessageEditor(),
                const SizedBox(height: 16),
                _buildStatsCard(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '选择联系人',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _contacts.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _selectAll = !_selectAll;
                              if (_selectAll) {
                                _selectedContacts = List.from(_contacts);
                              } else {
                                _selectedContacts.clear();
                              }
                            });
                          },
                    child: Text(
                      _selectAll ? '取消全选' : '全选',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _contacts.isEmpty
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator()),
                )
              : _buildContactsList(),
        ],
      ),
    );
  }

  Widget _buildMessageEditor() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.chat_bubble_text_fill,
                  color: Color(0xFFFF9500),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '短信内容',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CupertinoTextField(
              controller: _messageController,
              placeholder: '输入要发送的短信内容',
              maxLines: 5,
              padding: const EdgeInsets.all(16),
              decoration: null,
              style: const TextStyle(fontSize: 15, height: 1.5),
              placeholderStyle: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9500), Color(0xFFFFB340)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9500).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.person_2_fill,
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
                  '已选择 ${_selectedContacts.length} 位',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '共 ${_contacts.length} 位联系人',
                  style: TextStyle(
                    color: CupertinoColors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${_contacts.isEmpty ? 0 : ((_selectedContacts.length / _contacts.length) * 100).toInt()}%',
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    if (_contacts.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.person_crop_circle_badge_xmark,
                size: 64,
                color: CupertinoColors.systemGrey3,
              ),
              SizedBox(height: 16),
              Text(
                '没有找到联系人',
                style: TextStyle(
                  fontSize: 17,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final contact = _contacts[index];
            final isSelected = _selectedContacts.contains(contact);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? Border.all(
                        color: const Color(0xFFFF9500).withOpacity(0.3),
                        width: 2,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CupertinoButton(
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(14),
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
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFFFF9500)
                            : const Color(0xFFE5E5EA),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF9500)
                              : CupertinoColors.systemGrey4,
                          width: isSelected ? 0 : 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              CupertinoIcons.check_mark,
                              size: 16,
                              color: CupertinoColors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9500).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          contact.displayName.isNotEmpty
                              ? contact.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF9500),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? CupertinoColors.black
                                  : CupertinoColors.black,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (contact.phones.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                contact.phones.first.number,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.systemGrey,
                                ),
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
          childCount: _contacts.length,
        ),
      ),
    );
  }
}
