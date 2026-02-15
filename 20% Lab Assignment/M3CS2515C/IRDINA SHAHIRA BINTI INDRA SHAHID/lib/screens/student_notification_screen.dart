import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ict602_app/services/notification_service.dart';

// ========== STUDENT NOTIFICATION SCREEN ==========
class StudentNotificationScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  StudentNotificationScreen({required this.user});

  @override
  _StudentNotificationScreenState createState() => _StudentNotificationScreenState();
}

class _StudentNotificationScreenState extends State<StudentNotificationScreen> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _setupUnreadListener();
  }

  void _setupUnreadListener() {
    NotificationService.getUnreadCount(widget.user['uid']).listen((count) {
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('My Notifications'),
            if (_unreadCount > 0) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: NotificationService.getUserNotifications(widget.user['uid']),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No notifications yet'),
                  SizedBox(height: 5),
                  Text('Check back later for updates', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notifDoc = notifications[index];
              var notif = notifDoc.data() as Map<String, dynamic>;
              bool isRead = notif['read'] ?? false;
              return Dismissible(
              key: Key(notifDoc.id),
              direction: DismissDirection.endToStart,
              background: Container(
              color: Colors.green,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.check, color: Colors.white),
              ),
              onDismissed: (direction) async {
              await NotificationService.markAsRead(notifDoc.id);
              },
              child: Card(
              margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              color: isRead ? Colors.white : Colors.blue[50],
              child: ListTile(
              leading: Icon(
              _getNotificationIcon(notif['type']),
              color: _getNotificationColor(notif['type']),
              ),
              title: Text(
              notif['title'],
              style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              ),
              ),
              subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(notif['body']),
              SizedBox(height: 5),
              Text(
              _formatDate(notif['createdAt']),
              style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              ],
              ),
              trailing: isRead ? null : Icon(Icons.circle, size: 10, color: Colors.blue),
              onTap: () async {
              if (!isRead) {
              await NotificationService.markAsRead(notifDoc.id);
              }
              },
              ),
              ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'marks_update': return Icons.grade;
      case 'attendance': return Icons.event_note;
      case 'deadline': return Icons.timer;
      default: return Icons.announcement;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'marks_update': return Colors.green;
      case 'attendance': return Colors.orange;
      case 'deadline': return Colors.red;
      default: return Colors.blue;
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp.toDate();
    Duration diff = DateTime.now().difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }
}
