import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/project_chat.dart';
import '../providers/auth_provider.dart';
import '../repositories/project_chat_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/user_repository.dart';
import '../services/chat_message_filter.dart';

class ProjectChatScreen extends StatefulWidget {
  const ProjectChatScreen({
    required this.projectId,
    required this.projectTitle,
    super.key,
  });

  final String projectId;
  final String projectTitle;

  @override
  State<ProjectChatScreen> createState() => _ProjectChatScreenState();
}

class _ProjectChatScreenState extends State<ProjectChatScreen> {
  final _messageController = TextEditingController();
  late final Future<void> _accessFuture;
  bool _isSending = false;
  bool _isProjectOwner = false;
  bool _isSuperAdmin = false;
  String? _selectedChatId;
  String? _selectedChatTitle;
  String? _developerId;

  @override
  void initState() {
    super.initState();
    _accessFuture = _checkChatAccess();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkChatAccess() async {
    final authProvider = context.read<AuthProvider>();
    final projectRepository = context.read<ProjectRepository>();
    final userRepository = context.read<UserRepository>();
    final chatRepository = context.read<ProjectChatRepository>();
    final user = authProvider.currentUser;
    if (user == null) throw StateError('يرجى تسجيل الدخول لفتح المحادثة.');

    final project = await projectRepository.getProject(widget.projectId);
    if (project == null) throw StateError('المشروع غير موجود.');

    final developerId = project.developerId;
    if (developerId.isEmpty) {
      throw StateError('تعذر تحديد مطور المشروع.');
    }
    _developerId = developerId;
    _isProjectOwner = developerId == user.uid;

    final userDocument = await userRepository.getUserProfile(user.uid);
    _isSuperAdmin =
        userDocument?['userType'] == 'superAdmin' ||
        await authProvider.hasSuperAdminClaim();

    if (_isProjectOwner || _isSuperAdmin) return;

    final chatId = await chatRepository.createOrGetClientChat(
      projectId: widget.projectId,
      clientUid: user.uid,
      developerUid: developerId,
    );
    if (!mounted) return;
    setState(() {
      _selectedChatId = chatId;
      _selectedChatTitle = widget.projectTitle;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    if (!ChatMessageFilter.isMessageAllowed(text)) {
      _messageController.clear();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'نعتذر، لا يُسمح بتبادل أرقام الهواتف عبر المحادثة. '
              'يمكنك استخدام زر الواتساب المخصص للتواصل.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF26364F),
          ),
        );
      return;
    }

    if (text.length > 4000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب ألا تتجاوز الرسالة 4000 حرف.')),
      );
      return;
    }

    final user = context.read<AuthProvider>().currentUser;
    final chatId = _selectedChatId;
    if (user == null || chatId == null) return;

    setState(() => _isSending = true);
    try {
      final senderName =
          user.displayName ?? user.email?.split('@').first ?? 'مستخدم';
      await context.read<ProjectChatRepository>().sendMessage(
        chatId: chatId,
        senderId: user.uid,
        senderName: senderName,
        text: text,
      );
      _messageController.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر إرسال الرسالة: $error')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _senderLabel(String senderUid, String currentUid) {
    if (senderUid == currentUid) return 'أنت';
    if (_isSuperAdmin) return 'مشارك في المحادثة';
    return _isProjectOwner ? 'العميل' : 'المطور';
  }

  Widget _buildSenderName(
    ProjectChatMessage message,
    String senderUid,
    String currentUid,
  ) {
    final name = message.senderName.trim();
    final displayName = name.isNotEmpty
        ? name
        : _senderLabel(senderUid, currentUid);
    const style = TextStyle(
      color: Color(0xFF60A5FA),
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    if (senderUid == currentUid) {
      return const Text('أنت', style: style);
    }
    return Text(displayName, style: style);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: (_isProjectOwner || _isSuperAdmin) && _selectedChatId != null
              ? 'قائمة الاستفسارات'
              : 'رجوع',
          onPressed: () {
            if ((_isProjectOwner || _isSuperAdmin) && _selectedChatId != null) {
              setState(() {
                _selectedChatId = null;
                _selectedChatTitle = null;
              });
            } else {
              Navigator.maybePop(context);
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'استفسار / محادثة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              _selectedChatTitle ?? widget.projectTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: FutureBuilder<void>(
              future: _accessFuture,
              builder: (context, accessSnapshot) {
                if (accessSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  );
                }
                if (accessSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF94A3B8),
                            size: 44,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${accessSnapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFCBD5E1)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (_selectedChatId == null) {
                  return _buildConversationList();
                }

                return Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<ProjectChatMessage>>(
                        stream: context
                            .read<ProjectChatRepository>()
                            .watchMessages(_selectedChatId!),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'تعذر تحميل رسائل المحادثة: ${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            );
                          }
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF3B82F6),
                              ),
                            );
                          }
                          final messages = snapshot.data ?? const [];
                          if (messages.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.forum_outlined,
                                    size: 56,
                                    color: Color(0xFF475569),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'ابدأ المحادثة برسالتك الأولى',
                                    style: TextStyle(color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(20),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final senderUid = message.senderId;
                              final isOwnMessage = senderUid == user?.uid;
                              final sentAt = message.sentAt;
                              return Align(
                                    alignment: isOwnMessage
                                        ? AlignmentDirectional.centerStart
                                        : AlignmentDirectional.centerEnd,
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        maxWidth: 680,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOwnMessage
                                            ? const Color(0xFF1E3A5F)
                                            : const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFF334155),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildSenderName(
                                            message,
                                            senderUid,
                                            user?.uid ?? '',
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            message.text,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              height: 1.45,
                                            ),
                                          ),
                                          if (sentAt != null) ...[
                                            const SizedBox(height: 5),
                                            Text(
                                              '${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}',
                                              style: const TextStyle(
                                                color: Color(0xFF94A3B8),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  )
                                  .animate(
                                    delay: Duration(
                                      milliseconds: index.clamp(0, 12) * 8,
                                    ),
                                  )
                                  .fadeIn(duration: 180.ms)
                                  .slideY(begin: 0.02, end: 0);
                            },
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF111B2D),
                        border: Border(
                          top: BorderSide(color: Color(0xFF26364F)),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              minLines: 1,
                              maxLines: 5,
                              maxLength: 4000,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'اكتب رسالتك عن هذا المشروع...',
                                hintStyle: const TextStyle(
                                  color: Colors.white54,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF1E293B),
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 54,
                            width: 54,
                            child: IconButton.filled(
                              onPressed: _isSending ? null : _sendMessage,
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                              ),
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                              tooltip: 'إرسال الرسالة',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList() {
    return StreamBuilder<List<ProjectChat>>(
      stream: context.read<ProjectChatRepository>().watchProjectConversations(
        projectId: widget.projectId,
        developerUid: _developerId ?? '',
        isSuperAdmin: _isSuperAdmin,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'تعذر تحميل استفسارات المشروع: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        }

        final chats = snapshot.data ?? const [];
        if (chats.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    color: Color(0xFF64748B),
                    size: 44,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'لا توجد استفسارات لهذا المشروع بعد.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'ستظهر المحادثة هنا عندما يرسل أحد العملاء استفساراً.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final clientUid = chat.clientUid;
            final projectId = chat.projectId;
            return Card(
              color: const Color(0xFF1E293B),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF1E3A5F),
                    child: Icon(Icons.person_outline, color: Color(0xFF60A5FA)),
                  ),
                  title: const Text(
                    'استفسار عميل',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    _isSuperAdmin
                        ? 'المشروع: $projectId • العميل: $clientUid'
                        : clientUid,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  trailing: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF94A3B8),
                  ),
                  onTap: () => setState(() {
                    _selectedChatId = chat.id;
                    _selectedChatTitle = _isSuperAdmin && projectId.isNotEmpty
                        ? 'المشروع $projectId'
                        : widget.projectTitle;
                  }),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
