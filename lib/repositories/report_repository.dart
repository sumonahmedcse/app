import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_model.dart';

abstract class ReportRepository {
  Future<List<ReportModel>> getReports();
  Future<ReportModel> createReport(ReportModel report);
  Future<ReportModel> upvoteReport(String reportId, String userId);
  Future<ReportModel> updateReportStatus(String reportId, ReportStatus status, String? adminNotes);
  Future<ReportModel> updateReport(ReportModel updatedReport);
  Future<void> deleteReport(String reportId);
  Stream<List<ReportModel>> watchReports();
}

class MockReportRepository implements ReportRepository {
  final StreamController<List<ReportModel>> _reportsStreamController =
      StreamController<List<ReportModel>>.broadcast();
  List<ReportModel> _reports = [];

  static const String _reportsKey = 'mock_reports';

  MockReportRepository() {
    _initMockReports();
  }

  Future<void> _initMockReports() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (prefs.containsKey(_reportsKey)) {
      final reportsStr = prefs.getString(_reportsKey)!;
      final List<dynamic> decoded = jsonDecode(reportsStr);
      _reports = decoded.map((item) => ReportModel.fromMap(item)).toList();
    } else {
      // Seed some realistic campus issues
      _reports = [
        ReportModel(
          id: 'report_seed_1',
          title: 'Broken Projector in Room 402',
          description: 'The projector turns on but displays static lines. This is affecting CSE 6th Semester classes. Needs immediate technician review.',
          category: 'Classroom Equipment',
          imageUrl: 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=500&auto=format&fit=crop&q=60',
          latitude: 24.8967, // Coordinate for Pundra University area (Bogura)
          longitude: 89.3725,
          reportedBy: 'student_seed_1',
          reportedByName: 'Sumon Ahmed',
          reportedAt: DateTime.now().subtract(const Duration(days: 3)),
          status: ReportStatus.inProgress,
          upvotes: ['user_seed_2', 'user_seed_3', 'user_seed_4'],
          adminNotes: 'Technician has been called and will check on Wednesday morning.',
        ),
        ReportModel(
          id: 'report_seed_2',
          title: 'AC Water Leakage in CSE Lab 3',
          description: 'The split AC unit near the windows is dripping water constantly on the computer desk below. Had to move two desktop PCs to avoid water damage.',
          category: 'Laboratory',
          imageUrl: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500&auto=format&fit=crop&q=60',
          latitude: 24.8969,
          longitude: 89.3728,
          reportedBy: 'user_seed_5',
          reportedByName: 'Sadia Rahman',
          reportedAt: DateTime.now().subtract(const Duration(days: 1)),
          status: ReportStatus.pending,
          upvotes: ['student_seed_1', 'user_seed_3'],
          adminNotes: null,
        ),
        ReportModel(
          id: 'report_seed_3',
          title: 'Damaged Whiteboard in Seminar Hall',
          description: 'The whiteboard in the CSE Seminar Hall is deeply scratched and marker ink cannot be erased properly. It is making lectures hard to read.',
          category: 'Furniture',
          imageUrl: 'https://images.unsplash.com/photo-1571844307560-f551fa31d7a7?w=500&auto=format&fit=crop&q=60',
          latitude: 24.8965,
          longitude: 89.3722,
          reportedBy: 'user_seed_6',
          reportedByName: 'Amit Hasan',
          reportedAt: DateTime.now().subtract(const Duration(hours: 12)),
          status: ReportStatus.solved,
          upvotes: ['user_seed_2', 'user_seed_4', 'user_seed_5', 'user_seed_7'],
          adminNotes: 'Replaced with a brand new whiteboard on 2026-05-18.',
        ),
      ];
      await _saveToStorage();
    }
    _reportsStreamController.add(_reports);
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_reports.map((r) => r.toMap()).toList());
    await prefs.setString(_reportsKey, encoded);
  }

  @override
  Future<List<ReportModel>> getReports() async {
    // Sort by upvotes (descending) as default priority, then by date
    _reports.sort((a, b) {
      int upvoteCompare = b.upvotesCount.compareTo(a.upvotesCount);
      if (upvoteCompare != 0) return upvoteCompare;
      return b.reportedAt.compareTo(a.reportedAt);
    });
    return List.from(_reports);
  }

  @override
  Stream<List<ReportModel>> watchReports() {
    // Immediate seed update
    Future.microtask(() => _reportsStreamController.add(List.from(_reports)));
    return _reportsStreamController.stream;
  }

  @override
  Future<ReportModel> createReport(ReportModel report) async {
    await Future.delayed(const Duration(milliseconds: 1200)); // Simulate upload
    
    // Add to local list
    _reports.insert(0, report);
    await _saveToStorage();
    
    _reportsStreamController.add(List.from(_reports));
    return report;
  }

  @override
  Future<ReportModel> upvoteReport(String reportId, String userId) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final report = _reports[index];
      final List<String> newUpvotes = List.from(report.upvotes);
      
      if (newUpvotes.contains(userId)) {
        newUpvotes.remove(userId); // Toggle off upvote
      } else {
        newUpvotes.add(userId); // Toggle on upvote
      }
      
      final updatedReport = report.copyWith(upvotes: newUpvotes);
      _reports[index] = updatedReport;
      await _saveToStorage();
      _reportsStreamController.add(List.from(_reports));
      return updatedReport;
    }
    throw Exception('Report not found');
  }

  @override
  Future<ReportModel> updateReportStatus(
    String reportId,
    ReportStatus status,
    String? adminNotes,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final report = _reports[index];
      final updatedReport = report.copyWith(
        status: status,
        adminNotes: adminNotes,
      );
      _reports[index] = updatedReport;
      await _saveToStorage();
      _reportsStreamController.add(List.from(_reports));
      return updatedReport;
    }
    throw Exception('Report not found');
  }

  @override
  Future<ReportModel> updateReport(ReportModel updatedReport) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _reports.indexWhere((r) => r.id == updatedReport.id);
    if (index != -1) {
      _reports[index] = updatedReport;
      await _saveToStorage();
      _reportsStreamController.add(List.from(_reports));
      return updatedReport;
    }
    throw Exception('Report not found');
  }

  @override
  Future<void> deleteReport(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final initialLength = _reports.length;
    _reports.removeWhere((r) => r.id == reportId);
    if (_reports.length < initialLength) {
      await _saveToStorage();
      _reportsStreamController.add(List.from(_reports));
    } else {
      throw Exception('Report not found');
    }
  }
}
