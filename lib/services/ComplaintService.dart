import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/models/ComplaintModel.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:get/get.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ComplaintService
// ─────────────────────────────────────────────────────────────────────────────
class ComplaintService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colComplaints);

  // FR-7.1: Submit complaint
  Future<String> submitComplaint(ComplaintModel complaint) async {
    final docRef = await _col.add(complaint.toMap());
    return docRef.id;
  }

  // FR-7.2: Owner responds
  Future<void> respondToComplaint(
      String complaintId, String response, String status) async {
    await _col.doc(complaintId).update({
      'ownerResponse': response,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Student complaints — sort client-side to avoid index
  Stream<List<ComplaintModel>> getStudentComplaintsStream(String studentId) {
    return _col
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }

  // Owner complaints — sort client-side
  Stream<List<ComplaintModel>> getOwnerComplaintsStream(String ownerId) {
    return _col
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }

  // Student confirms resolution status
  Future<void> confirmResolution(String complaintId, bool confirmed) async {
    await _col.doc(complaintId).update({
      'studentConfirmed': confirmed,
      'status': confirmed ? 'resolved' : 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // All complaints admin — sort client-side
  Stream<List<ComplaintModel>> getAllComplaintsStream() {
    return _col
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }

  // Complaints for a specific hostel — sort client-side
  Stream<List<ComplaintModel>> getHostelComplaintsStream(String hostelId) {
    return _col
        .where('hostelId', isEqualTo: hostelId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }
}
