import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final authHeaders = await ApiService.headers();
      final res = await http.get(Uri.parse('${ApiService.baseUrl}/notifications'), headers: authHeaders).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        setState(() {
          _notifications = jsonDecode(res.body);
          _unreadCount = _notifications.where((n) => n['is_read'] == false).length;
          _loading = false;
        });
      } else {
        throw Exception('Failed');
      }
    } catch (e) {
      setState(() { _error = 'Could not load notifications.'; _loading = false; });
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      final authHeaders = await ApiService.headers();
      await http.patch(Uri.parse('${ApiService.baseUrl}/notifications/$id/read'), headers: authHeaders);
      setState(() {
        final idx = _notifications.indexWhere((n) => n['id'] == id);
        if (idx != -1) { _notifications[idx]['is_read'] = true; _unreadCount = _notifications.where((n) => n['is_read'] == false).length; }
      });
    } catch (_) {}
  }

  void _showDetail(String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [color.withOpacity(0.1), Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 60, height: 60, decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 30)),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pop(ctx), style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Close', style: TextStyle(color: Colors.white))),
          ]),
        ),
      ),
    );
  }

  IconData _getIcon(String? name) {
    switch (name) {
      case 'waving_hand': return Icons.waving_hand;
      case 'lock_open': return Icons.lock_open;
      case 'assignment': return Icons.assignment_turned_in;
      case 'tips': return Icons.tips_and_updates;
      case 'achievement': return Icons.emoji_events;
      default: return Icons.notifications;
    }
  }

  Color _getColor(String? icon) {
    switch (icon) {
      case 'waving_hand': return Colors.orange;
      case 'lock_open': return Colors.green;
      case 'assignment': return Colors.blue;
      case 'tips': return Colors.purple;
      case 'achievement': return Colors.amber;
      default: return AppColors.primaryGradientStart;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400), const SizedBox(height: 16),
        Text(_error!, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)), const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: _fetchNotifications, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ])) : _notifications.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400), const SizedBox(height: 16),
        Text('No notifications yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
      ])) : RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _notifications.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = _notifications[index];
            final isUnread = item['is_read'] == false;
            final color = _getColor(item['icon']);

            return GestureDetector(
              onTap: () {
                _markAsRead(item['id']);
                _showDetail(item['title'] ?? '', item['message'] ?? '', _getIcon(item['icon']), color);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isUnread ? color.withOpacity(0.3) : theme.colorScheme.onSurface.withOpacity(0.06)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(_getIcon(item['icon']), color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(item['title'] ?? '', style: TextStyle(fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500, color: theme.colorScheme.onSurface, fontSize: 15))),
                      if (isUnread) Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    ]),
                    const SizedBox(height: 4),
                    Text(item['message'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(_formatDate(item['created_at']), style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                  ])),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) { return ''; }
  }
}