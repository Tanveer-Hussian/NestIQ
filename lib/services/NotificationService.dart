// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fyp/utils/AppConstants.dart';
// import 'package:get/get.dart';
// import 'package:fyp/models/NotificationModel.dart';


// // NotificationService
// // ─────────────────────────────────────────────────────────────────────────────
// class NotificationService extends GetxService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   CollectionReference<Map<String, dynamic>> get _col =>
//       _db.collection(AppConstants.colNotifications);

//   // FR-9.x: Send notification
//   Future<void> sendNotification({
//     required String userId,
//     required String title,
//     required String body,
//     required String type,
//     String? relatedId,
//   }) async {
//     await _col.add({
//       'userId': userId,
//       'title': title,
//       'body': body,
//       'type': type,
//       'relatedId': relatedId,
//       'isRead': false,
//       'createdAt': FieldValue.serverTimestamp(),
//     });
//   }

//   // User notifications — where+orderBy needs index, so sort client-side
//   // This was the query causing FAILED_PRECONDITION crash on student home screen
//   Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
//     return _col
//         .where('userId', isEqualTo: userId)
//         // REMOVED: .orderBy('createdAt', descending: true)
//         // That combo requires a composite index. Sort client-side instead.
//         .limit(50)
//         .snapshots()
//         .map((snap) {
//           final list = snap.docs
//               .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
//               .toList();
//           // Sort client-side — newest first
//           list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
//           return list;
//         });
//   }

//   // Mark one notification as read
//   Future<void> markAsRead(String notificationId) async {
//     await _col.doc(notificationId).update({'isRead': true});
//   }

//   // Mark all notifications as read
//   Future<void> markAllAsRead(String userId) async {
//     final batch = _db.batch();
//     final snap = await _col
//         .where('userId', isEqualTo: userId)
//         .where('isRead', isEqualTo: false)
//         .get();
//     for (final doc in snap.docs) {
//       batch.update(doc.reference, {'isRead': true});
//     }
//     await batch.commit();
//   }
// }




// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/models/NotificationModel.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:get/get.dart';

class NotificationService extends GetxService {

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colNotifications);
 
  // FR-9.x: Send notification
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    await _col.add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
 
  // User notifications — where+orderBy needs index, so sort client-side
  // This was the query causing FAILED_PRECONDITION crash on student home screen
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        // REMOVED: .orderBy('createdAt', descending: true)
        // That combo requires a composite index. Sort client-side instead.
        .limit(50)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort client-side — newest first
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }
 
  // Mark one notification as read
  Future<void> markAsRead(String notificationId) async {
    await _col.doc(notificationId).update({'isRead': true});
  }
 
  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final batch = _db.batch();
    final snap = await _col
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
