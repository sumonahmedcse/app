enum ReportStatus {
  pending,
  inProgress,
  solved,
  rejected,
}

extension ReportStatusExtension on ReportStatus {
  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.solved:
        return 'Solved';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }
}

class ReportModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String reportedBy;
  final String reportedByName;
  final DateTime reportedAt;
  final ReportStatus status;
  final List<String> upvotes; // List of user UIDs who upvoted
  final String? adminNotes;

  ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.reportedBy,
    required this.reportedByName,
    required this.reportedAt,
    this.status = ReportStatus.pending,
    required this.upvotes,
    this.adminNotes,
  });

  int get upvotesCount => upvotes.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'reportedBy': reportedBy,
      'reportedByName': reportedByName,
      'reportedAt': reportedAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'upvotes': upvotes,
      'adminNotes': adminNotes,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'],
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      reportedBy: map['reportedBy'] ?? '',
      reportedByName: map['reportedByName'] ?? '',
      reportedAt: map['reportedAt'] != null
          ? DateTime.parse(map['reportedAt'])
          : DateTime.now(),
      status: parseReportStatus(map['status']),
      upvotes: List<String>.from(map['upvotes'] ?? []),
      adminNotes: map['adminNotes'],
    );
  }

  ReportModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? reportedBy,
    String? reportedByName,
    DateTime? reportedAt,
    ReportStatus? status,
    List<String>? upvotes,
    String? adminNotes,
  }) {
    return ReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedByName: reportedByName ?? this.reportedByName,
      reportedAt: reportedAt ?? this.reportedAt,
      status: status ?? this.status,
      upvotes: upvotes ?? this.upvotes,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }

  static ReportStatus parseReportStatus(String? statusStr) {
    switch (statusStr) {
      case 'inProgress':
        return ReportStatus.inProgress;
      case 'solved':
        return ReportStatus.solved;
      case 'rejected':
        return ReportStatus.rejected;
      case 'pending':
      default:
        return ReportStatus.pending;
    }
  }
}
