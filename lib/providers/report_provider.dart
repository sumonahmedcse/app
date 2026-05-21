import 'dart:async';
import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../repositories/report_repository.dart';
import '../repositories/service_locator.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository _reportRepository = ServiceLocator.reportRepository;

  List<ReportModel> _allReports = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<ReportModel>>? _reportsSubscription;

  // Filter properties
  String _selectedCategory = 'All';
  ReportStatus? _selectedStatus;
  String _searchQuery = '';

  List<ReportModel> get reports {
    return _allReports.where((report) {
      final matchesCategory = _selectedCategory == 'All' ||
          report.category.toLowerCase() == _selectedCategory.toLowerCase();
      
      final matchesStatus = _selectedStatus == null ||
          report.status == _selectedStatus;

      final matchesSearch = report.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.category.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesStatus && matchesSearch;
    }).toList();
  }

  // Statistics for Admin Dashboard
  int get totalReportsCount => _allReports.length;
  int get pendingReportsCount => _allReports.where((r) => r.status == ReportStatus.pending).length;
  int get inProgressReportsCount => _allReports.where((r) => r.status == ReportStatus.inProgress).length;
  int get solvedReportsCount => _allReports.where((r) => r.status == ReportStatus.solved).length;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  ReportStatus? get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;

  ReportProvider() {
    _subscribeToReports();
  }

  void _subscribeToReports() {
    _isLoading = true;
    _reportsSubscription = _reportRepository.watchReports().listen(
      (reportsList) {
        _allReports = reportsList;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> fetchReports() async {
    _setLoading(true);
    try {
      _allReports = await _reportRepository.getReports();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createReport({
    required String title,
    required String description,
    required String category,
    required String? imagePath,
    required double latitude,
    required double longitude,
    required String userId,
    required String userName,
  }) async {
    _setLoading(true);
    try {
      final newReport = ReportModel(
        id: 'report_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
        category: category,
        imageUrl: imagePath,
        latitude: latitude,
        longitude: longitude,
        reportedBy: userId,
        reportedByName: userName,
        reportedAt: DateTime.now(),
        status: ReportStatus.pending,
        upvotes: [],
      );
      
      await _reportRepository.createReport(newReport);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> upvoteReport(String reportId, String userId) async {
    try {
      await _reportRepository.upvoteReport(reportId, userId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> updateReportStatus(
    String reportId,
    ReportStatus status,
    String? adminNotes,
  ) async {
    _setLoading(true);
    try {
      await _reportRepository.updateReportStatus(reportId, status, adminNotes);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateReport(ReportModel updatedReport) async {
    _setLoading(true);
    try {
      await _reportRepository.updateReport(updatedReport);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteReport(String reportId) async {
    _setLoading(true);
    try {
      await _reportRepository.deleteReport(reportId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Filters management
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setStatus(ReportStatus? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = 'All';
    _selectedStatus = null;
    _searchQuery = '';
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    super.dispose();
  }
}
