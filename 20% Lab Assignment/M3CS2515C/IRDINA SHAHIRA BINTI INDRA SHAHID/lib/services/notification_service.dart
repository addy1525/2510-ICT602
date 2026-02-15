import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

// ========== NOTIFICATION SERVICE (OPTIMIZED) ==========
class NotificationService {
static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Caching for better performance
static final Map<String, List<Map<String, dynamic>>> _notificationCache = {};
static DateTime? _lastCacheRefresh;

// Send notification to specific user
static Future<void> sendNotificationToUser({
required String userId,
required String title,
required String body,
required String type,
Map<String, dynamic>? data,
}) async {
try {
await _firestore.collection('user_notifications').add({
'userId': userId,
'title': title,
'body': body,
'type': type,
'data': data ?? {},
'read': false,
'createdAt': FieldValue.serverTimestamp(),
});

// Invalidate cache for this user
_notificationCache.remove('$userId-${DateTime.now().day}');
print('✅ Notification saved to Firestore for user: $userId');

} catch (e) {
print('❌ Error sending notification: $e');
}
}

// Send notification to all students
static Future<void> notifyAllStudents({
required String title,
required String body,
required String type,
required String courseCode,
Map<String, dynamic>? data,
}) async {
try {
QuerySnapshot students = await _firestore
    .collection('users')
    .where('role', isEqualTo: 'student')
    .get();

int successCount = 0;
List<String> studentIds = [];

for (var doc in students.docs) {
await _firestore.collection('user_notifications').add({
'userId': doc.id,
'title': title,
'body': body,
'type': type,
'data': data ?? {},
'courseCode': courseCode,
'read': false,
'createdAt': FieldValue.serverTimestamp(),
});

studentIds.add(doc.id);
successCount++;
}

await _firestore.collection('broadcast_notifications').add({
'title': title,
'body': body,
'type': type,
'courseCode': courseCode,
'sentBy': FirebaseAuth.instance.currentUser?.uid,
'sentToCount': successCount,
'studentIds': studentIds,
'createdAt': FieldValue.serverTimestamp(),
});

print('✅ Broadcast notification sent to $successCount students');

} catch (e) {
print('❌ Error broadcasting notification: $e');
}
}

// OPTIMIZED: Get user notifications with pagination
static Stream<QuerySnapshot> getUserNotifications(String userId, {int limit = 20}) {
return _firestore
    .collection('user_notifications')
    .where('userId', isEqualTo: userId)
    .orderBy('createdAt', descending: true)
    .limit(limit)
    .snapshots();
}

// CACHED VERSION for better performance
static Future<List<Map<String, dynamic>>> getCachedNotifications(String userId) async {
final cacheKey = '$userId-${DateTime.now().day}';

// Return cached data if available and not expired (5 minutes)
if (_notificationCache.containsKey(cacheKey) &&
_lastCacheRefresh != null &&
DateTime.now().difference(_lastCacheRefresh!) < Duration(minutes: 5)) {
return _notificationCache[cacheKey]!;
}

// Fetch from Firestore
final querySnapshot = await _firestore
    .collection('user_notifications')
    .where('userId', isEqualTo: userId)
    .orderBy('createdAt', descending: true)
    .limit(30)
    .get();
final notifications = querySnapshot.docs.map((doc) {
return {
'id': doc.id,
...doc.data() as Map<String, dynamic>,
};
}).toList();

// Cache the results
_notificationCache[cacheKey] = notifications;
_lastCacheRefresh = DateTime.now();

return notifications;
}

// Mark notification as read
static Future<void> markAsRead(String notificationId) async {
await _firestore
    .collection('user_notifications')
    .doc(notificationId)
    .update({'read': true});
}

// Get notification count - OPTIMIZED
static Stream<int> getUnreadCount(String userId) {
return _firestore
    .collection('user_notifications')
    .where('userId', isEqualTo: userId)
    .where('read', isEqualTo: false)
    .orderBy('createdAt', descending: true)
    .limit(100) // Add limit for performance
    .snapshots()
    .map((snapshot) => snapshot.docs.length);
}
}