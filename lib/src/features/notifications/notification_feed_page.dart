import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';

class NotificationFeedPage extends StatefulWidget {
  static const route = '/notifications-feed';
  const NotificationFeedPage({super.key});

  @override
  State<NotificationFeedPage> createState() => _NotificationFeedPageState();
}

class _NotificationFeedPageState extends State<NotificationFeedPage> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifications = await NotificationService.getNotifications();
    await NotificationService.markAllAsRead();
    if (mounted) {
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    }
  }

  Map<String, List<AppNotification>> _groupByDate() {
    final Map<String, List<AppNotification>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final n in _notifications) {
      final date =
          DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      String label;
      if (date == today) {
        label = 'Today';
      } else if (date == yesterday) {
        label = 'Yesterday';
      } else {
        label = '${date.day}/${date.month}/${date.year}';
      }
      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(n);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Notification'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No notifications yet',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: _buildGroupedList(),
                  ),
                ),
    );
  }

  List<Widget> _buildGroupedList() {
    final grouped = _groupByDate();
    final widgets = <Widget>[];

    for (final entry in grouped.entries) {
      widgets.add(_Label(entry.key));
      widgets.add(const SizedBox(height: 8));
      for (final notification in entry.value) {
        widgets.add(_SimpleNotificationCard(
          title: notification.title,
          body: notification.body,
          time: notification.timeAgo,
        ));
      }
      widgets.add(const SizedBox(height: 8));
    }
    return widgets;
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: Color(0xFF6B7280)));
  }
}

/// iPhone-like card WITHOUT app name/logo — just Title, Time (right), Body.
class _SimpleNotificationCard extends StatelessWidget {
  /// Parse AQI value from body text (format: "AQI: 125 (...")
  int? _parseAqi() {
    final match = RegExp(r'AQI:\s*(\d+)').firstMatch(body);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  /// Get title color based on notification type
  Color _getTitleColor(int? aqi) {
    // If this is an event creation notification, set to blue
    if (title.toLowerCase().contains('event created') ||
        title.toLowerCase().contains('event has been created') ||
        body.toLowerCase().contains('event has been created')) {
      return const Color(0xFF2563EB); // Blue
    }
    // Otherwise, use AQI logic
    if (aqi == null) return const Color(0xFF16A34A); // Default green
    if (aqi <= 50) return const Color(0xFF16A34A); // Green - Good
    if (aqi <= 100) return const Color(0xFFCA8A04); // Yellow - Moderate
    return const Color(0xFFDC2626); // Red - Unhealthy
  }

  final String title;
  final String body;
  final String time;

  const _SimpleNotificationCard({
    required this.title,
    required this.body,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final aqi = _parseAqi();
    final titleColor = _getTitleColor(aqi);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE6E8EC)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 14,
                    offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + time (time on the right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ) ??
                            TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(time,
                        style: const TextStyle(color: Color(0xFF6B7280))),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: text.bodyMedium
                          ?.copyWith(color: const Color(0xFF1F2937)) ??
                      const TextStyle(color: Color(0xFF1F2937)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
