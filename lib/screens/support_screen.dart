import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/support_admin_repository.dart';
import '../theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _repo = const SupportAdminRepository();
  String _role = 'customer';
  String? _selectedId;
  final _messageController = TextEditingController();
  bool _sending = false;
  int _refreshKey = 0;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('$_role-$_refreshKey'),
      future: _repo.fetchConversations(role: _role),
      builder: (context, snapshot) {
        final conversations = snapshot.data ?? const [];
        final selectedMatches = conversations
            .where((e) => e['id']?.toString() == _selectedId)
            .toList();
        final selected = selectedMatches.isEmpty ? null : selectedMatches.first;
        final selectedId = selected?['id']?.toString();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 26, 28, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Help & Support',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Customer and mechanic support conversations',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  _roleTab('Customers', 'customer', Icons.person_outline),
                  const SizedBox(width: 8),
                  _roleTab(
                    'Mechanics',
                    'mechanic',
                    Icons.build_circle_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Row(
                  children: [
                    SizedBox(
                      width: 330,
                      child: SectionCard(
                        padding: EdgeInsets.zero,
                        child:
                            snapshot.connectionState == ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator())
                            : conversations.isEmpty
                            ? const Center(
                                child: Text('No support conversations yet.'),
                              )
                            : ListView.separated(
                                itemCount: conversations.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final c = conversations[index];
                                  final user = c['user'] is Map
                                      ? Map<String, dynamic>.from(c['user'])
                                      : <String, dynamic>{};
                                  final id = c['id'].toString();
                                  final selectedCard = id == _selectedId;
                                  final dt = DateTime.tryParse(
                                    c['last_message_at']?.toString() ?? '',
                                  )?.toLocal();
                                  return ListTile(
                                    selected: selectedCard,
                                    selectedTileColor: AppColors.primary
                                        .withValues(alpha: .06),
                                    onTap: () {
                                      setState(() => _selectedId = id);
                                      _repo.markRead(id);
                                    },
                                    leading: CircleAvatar(
                                      backgroundColor: _role == 'mechanic'
                                          ? AppColors.accent.withValues(
                                              alpha: .18,
                                            )
                                          : AppColors.primary.withValues(
                                              alpha: .1,
                                            ),
                                      child: Icon(
                                        _role == 'mechanic'
                                            ? Icons.build
                                            : Icons.person,
                                        size: 18,
                                        color: _role == 'mechanic'
                                            ? AppColors.accent
                                            : AppColors.primary,
                                      ),
                                    ),
                                    title: Text(
                                      user['full_name']?.toString() ?? 'User',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      user['email']?.toString() ?? 'No email',
                                      style: const TextStyle(fontSize: 10.5),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: dt == null
                                        ? null
                                        : Text(
                                            DateFormat('d MMM').format(dt),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: selectedId == null
                          ? const SectionCard(
                              child: Center(
                                child: Text(
                                  'Select a customer or mechanic conversation.',
                                ),
                              ),
                            )
                          : _SupportConversationPanel(
                              key: ValueKey(selectedId),
                              repository: _repo,
                              conversationId: selectedId,
                              controller: _messageController,
                              sending: _sending,
                              onSend: _send,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _roleTab(String label, String role, IconData icon) {
    final selected = _role == role;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _role = role;
          _selectedId = null;
        }),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final id = _selectedId;
    final text = _messageController.text.trim();
    if (_sending || id == null || text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _repo.sendMessage(conversationId: id, message: text);
      _messageController.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _SupportConversationPanel extends StatelessWidget {
  final SupportAdminRepository repository;
  final String conversationId;
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _SupportConversationPanel({
    super.key,
    required this.repository,
    required this.conversationId,
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                Icon(Icons.support_agent_outlined),
                SizedBox(width: 9),
                Text(
                  'Support Conversation',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: repository.watchMessages(conversationId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const [];
                if (messages.isEmpty)
                  return const Center(child: Text('No messages yet.'));
                return ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final admin = m['sender_role'] == 'admin';
                    final time = DateTime.tryParse(
                      m['created_at']?.toString() ?? '',
                    )?.toLocal();
                    return Align(
                      alignment: admin
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 620),
                        margin: const EdgeInsets.only(bottom: 9),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: admin ? AppColors.primary : AppColors.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: admin
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              m['message']?.toString() ?? '',
                              style: TextStyle(
                                color: admin ? Colors.white : AppColors.text,
                                fontSize: 13,
                              ),
                            ),
                            if (time != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  DateFormat('d MMM, h:mm a').format(time),
                                  style: TextStyle(
                                    color: admin
                                        ? Colors.white70
                                        : AppColors.textMuted,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: const InputDecoration(
                      hintText: 'Reply to user...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: sending ? null : onSend,
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}
