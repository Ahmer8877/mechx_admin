import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupportAdminRepository {
  const SupportAdminRepository();

  Future<List<Map<String, dynamic>>> fetchConversations({String? role}) async {
    var query = supabase
        .from('support_conversations')
        .select(
          'id,user_id,status,created_at,updated_at,last_message_at,user:profiles!support_conversations_user_id_fkey(id,full_name,email,role,phone_number)',
        );
    final rows = await query.order(
      'last_message_at',
      ascending: false,
      nullsFirst: false,
    );
    final list = List<Map<String, dynamic>>.from(rows as List);
    if (role == null) return list;
    return list.where((row) {
      final user = row['user'];
      return user is Map && user['role']?.toString() == role;
    }).toList();
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) {
    return supabase
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at');
  }

  Future<void> sendMessage({
    required String conversationId,
    required String message,
  }) async {
    final adminId = supabase.auth.currentUser?.id;
    if (adminId == null || message.trim().isEmpty) return;
    await supabase.from('support_messages').insert({
      'conversation_id': conversationId,
      'sender_id': adminId,
      'sender_role': 'admin',
      'message': message.trim(),
    });
  }

  Future<void> markRead(String conversationId) async {
    try {
      await supabase
          .from('support_messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_role', 'admin');
    } on PostgrestException {
      // Read state is non-critical; do not interrupt the support conversation.
    }
  }
}
