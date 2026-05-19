import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/report_model.dart';
import 'report_repository.dart';

class FirebaseReportRepository implements ReportRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _reportsCollection =>
      _firestore.collection('reports');

  @override
  Future<List<ReportModel>> getReports() async {
    try {
      final snapshot = await _reportsCollection
          .orderBy('reportedAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching reports from Firestore: $e');
      rethrow;
    }
  }

  @override
  Stream<List<ReportModel>> watchReports() {
    return _reportsCollection
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data()))
          .toList();
      
      // Sort in-memory to ensure upvote order priority when loading
      list.sort((a, b) {
        int upvoteCompare = b.upvotesCount.compareTo(a.upvotesCount);
        if (upvoteCompare != 0) return upvoteCompare;
        return b.reportedAt.compareTo(a.reportedAt);
      });
      return list;
    });
  }

  @override
  Future<ReportModel> createReport(ReportModel report) async {
    try {
      String? uploadedImageUrl = report.imageUrl;

      // If imageUrl points to a local file path (starts with / or has path characteristics)
      // we need to upload it to Firebase Storage.
      if (report.imageUrl != null &&
          !report.imageUrl!.startsWith('http') &&
          !report.imageUrl!.startsWith('assets')) {
        final File file = File(report.imageUrl!);
        if (await file.exists()) {
          final storageRef = _storage
              .ref()
              .child('report_images/${report.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
          final uploadTask = await storageRef.putFile(file);
          uploadedImageUrl = await uploadTask.ref.getDownloadURL();
        }
      }

      final updatedReport = report.copyWith(imageUrl: uploadedImageUrl);
      await _reportsCollection.doc(report.id).set(updatedReport.toMap());
      return updatedReport;
    } catch (e) {
      print('Error creating report: $e');
      rethrow;
    }
  }

  @override
  Future<ReportModel> upvoteReport(String reportId, String userId) async {
    try {
      final docRef = _reportsCollection.doc(reportId);
      
      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('Report not found');
        }
        
        final report = ReportModel.fromMap(snapshot.data()!);
        final List<String> newUpvotes = List.from(report.upvotes);
        
        if (newUpvotes.contains(userId)) {
          newUpvotes.remove(userId);
        } else {
          newUpvotes.add(userId);
        }
        
        final updatedReport = report.copyWith(upvotes: newUpvotes);
        transaction.update(docRef, {'upvotes': newUpvotes});
        return updatedReport;
      });
    } catch (e) {
      print('Error upvoting report: $e');
      rethrow;
    }
  }

  @override
  Future<ReportModel> updateReportStatus(
    String reportId,
    ReportStatus status,
    String? adminNotes,
  ) async {
    try {
      final docRef = _reportsCollection.doc(reportId);
      final updateData = {
        'status': status.toString().split('.').last,
        'adminNotes': adminNotes,
      };
      await docRef.update(updateData);
      
      final updatedSnapshot = await docRef.get();
      return ReportModel.fromMap(updatedSnapshot.data()!);
    } catch (e) {
      print('Error updating report status: $e');
      rethrow;
    }
  }
}
