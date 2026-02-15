import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ict602_app/services/notification_service.dart';

// ========== NOTIFICATION SCREEN ==========
class NotificationScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  NotificationScreen({required this.user});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String _selectedType = 'announcement';
  bool _sending = false;
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

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty ||  _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill title and message')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      await NotificationService.notifyAllStudents(
        title: _titleController.text,
        body: _bodyController.text,
        type: _selectedType,
        courseCode: 'ICT602',
        data: {
          'lecturerName': widget.user['name'],
          'lecturerStaffNo': widget.user['staffNo'],
          'priority': 'high',
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification sent to all students!')),
      );

      _titleController.clear();
      _bodyController.clear();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Notifications'),
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
      body: Column(
        children: [
          Card(
            margin: EdgeInsets.all(15),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Text('SEND NOTIFICATION', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Notification Type',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'announcement', child: Text('Announcement')),
                      DropdownMenuItem(value: 'marks_update', child: Text('Marks Update')),
                      DropdownMenuItem(value: 'attendance', child: Text('Attendance Alert')),
                      DropdownMenuItem(value: 'deadline', child: Text('Deadline Reminder')),
                    ],
                    onChanged: (value) => setState(() => _selectedType = value!),
                  ),

                  SizedBox(height: 15),

                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Marks Updated',
                    ),
                  ),
                  SizedBox(height: 15),

                  TextField(
                    controller: _bodyController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Your ICT602 marks have been uploaded',
                    ),
                  ),

                  SizedBox(height: 20),

                  _sending
                      ? CircularProgressIndicator()
                      : ElevatedButton.icon(
                    onPressed: _sendNotification,
                    icon: Icon(Icons.send),
                    label: Text('SEND TO ALL STUDENTS'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
          ),
        ],
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
