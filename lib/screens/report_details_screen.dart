import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../theme/app_theme.dart';

class ReportDetailsScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailsScreen({super.key, required this.reportId});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _copyCoordinates(double lat, double lng) {
    Clipboard.setData(ClipboardData(text: '$lat, $lng'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coordinates copied to clipboard!')),
    );
  }

  void _showResolutionDialog(ReportModel report) {
    _notesController.text = report.adminNotes ?? '';
    ReportStatus selectedStatus = report.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Update Problem Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // Status Toggles
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ReportStatus.values.map((status) {
                      final isSelected = selectedStatus == status;
                      final statusColor = AppTheme.getStatusColor(status);
                      return ChoiceChip(
                        label: Text(status.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              selectedStatus = status;
                            });
                          }
                        },
                        selectedColor: statusColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: FontWeight.bold,
                        ),
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  
                  // Remarks Notes
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Resolution Remarks / Admin Notes',
                      hintText: 'Describe actions taken or updates on fixing the problem...',
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Button
                  ElevatedButton(
                    onPressed: () async {
                      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
                      Navigator.pop(context); // close bottom sheet
                      
                      final success = await reportProvider.updateReportStatus(
                        report.id,
                        selectedStatus,
                        _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                      );
                      
                      if (mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Status updated successfully!'),
                              backgroundColor: AppTheme.solvedColor,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(reportProvider.errorMessage ?? 'Update failed'),
                              backgroundColor: AppTheme.rejectedColor,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.getStatusColor(selectedStatus),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm Update'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final reportProvider = Provider.of<ReportProvider>(context);
    
    // Find the current report in the feed list
    final reportIndex = reportProvider.reports.indexWhere((r) => r.id == widget.reportId);
    if (reportIndex == -1) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Report details not found')),
      );
    }
    
    final report = reportProvider.reports[reportIndex];
    final user = authProvider.currentUser;
    final userId = user?.uid ?? '';
    final isUpvoted = report.upvotes.contains(userId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Problem Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Image
            _buildHeaderImage(report),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Category
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          report.category,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(report.reportedAt),
                        style: TextStyle(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    report.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Reported By Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(
                          report.reportedByName.isNotEmpty ? report.reportedByName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reported by ${report.reportedByName}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            DateFormat('h:mm a').format(report.reportedAt),
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Status Timeline Tracking Card
                  _buildStatusStepper(context, report.status),
                  const SizedBox(height: 24),
                  
                  // Upvote priority widget
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            '${report.upvotesCount} Upvotes',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(Priority Rating)',
                            style: TextStyle(
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      // Upvote Action Button
                      if (user?.role == UserRole.student)
                        ElevatedButton.icon(
                          onPressed: () {
                            if (userId.isNotEmpty) {
                              reportProvider.upvoteReport(report.id, userId);
                            }
                          },
                          icon: Icon(
                            isUpvoted ? Icons.arrow_upward : Icons.arrow_upward_outlined,
                            size: 18,
                            color: isUpvoted ? Colors.white : AppTheme.primaryColor,
                          ),
                          label: Text(isUpvoted ? 'Upvoted' : 'Upvote'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isUpvoted ? AppTheme.primaryColor : Colors.transparent,
                            foregroundColor: isUpvoted ? Colors.white : AppTheme.primaryColor,
                            side: const BorderSide(color: AppTheme.primaryColor),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: isUpvoted ? 2 : 0,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Problem Description
                  Text(
                    'Problem Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.description,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // GPS Coordinates Info Card
                  Text(
                    'GPS Capture Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceDark : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.borderDark : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.grey),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lat: ${report.latitude.toStringAsFixed(6)}',
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                                ),
                                Text(
                                  'Lng: ${report.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_all_outlined, size: 20),
                          onPressed: () => _copyCoordinates(report.latitude, report.longitude),
                          tooltip: 'Copy Coordinates',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Admin Resolution remarks section (if available)
                  if (report.adminNotes != null && report.adminNotes!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.getStatusColor(report.status).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.getStatusColor(report.status).withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                color: AppTheme.getStatusColor(report.status),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Resolution Notes from Admin',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getStatusColor(report.status),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            report.adminNotes!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Admin Action Button
                  if (user?.role == UserRole.admin) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showResolutionDialog(report),
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Update Complaint Status'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage(ReportModel report) {
    if (report.imageUrl == null) {
      return Container(
        height: 240,
        color: AppTheme.primaryColor.withOpacity(0.05),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported_outlined, size: 64, color: AppTheme.primaryColor),
              SizedBox(height: 8),
              Text(
                'No Image Provided',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ],
          ),
        ),
      );
    }

    if (report.imageUrl!.startsWith('http')) {
      return Image.network(
        report.imageUrl!,
        height: 240,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 240,
            color: Colors.grey.shade200,
            child: const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.grey)),
          );
        },
      );
    }

    return Image.file(
      File(report.imageUrl!),
      height: 240,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 240,
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.grey)),
        );
      },
    );
  }

  Widget _buildStatusStepper(BuildContext context, ReportStatus currentStatus) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Status items
    final List<Map<String, dynamic>> statusSteps = [
      {'status': ReportStatus.pending, 'label': 'Pending'},
      {'status': ReportStatus.inProgress, 'label': 'In Progress'},
      {'status': ReportStatus.solved, 'label': 'Solved'},
    ];

    if (currentStatus == ReportStatus.rejected) {
      statusSteps[2] = {'status': ReportStatus.rejected, 'label': 'Rejected'};
    }

    int currentStepIndex = 0;
    if (currentStatus == ReportStatus.inProgress) {
      currentStepIndex = 1;
    } else if (currentStatus == ReportStatus.solved || currentStatus == ReportStatus.rejected) {
      currentStepIndex = 2;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
            child: Text(
              'Complaint Lifecycle Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Row(
            children: List.generate(statusSteps.length * 2 - 1, (index) {
              if (index.isOdd) {
                // Divider line
                final lineIndex = index ~/ 2;
                final isCompleted = currentStepIndex > lineIndex;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: isCompleted
                        ? AppTheme.getStatusColor(statusSteps[lineIndex + 1]['status'])
                        : Colors.grey.shade300,
                  ),
                );
              } else {
                // Node
                final stepIndex = index ~/ 2;
                final stepStatus = statusSteps[stepIndex]['status'] as ReportStatus;
                final stepLabel = statusSteps[stepIndex]['label'] as String;
                
                final isCurrent = currentStepIndex == stepIndex;
                final isCompleted = currentStepIndex >= stepIndex;
                
                final stepColor = isCompleted
                    ? AppTheme.getStatusColor(stepStatus)
                    : Colors.grey.shade300;

                return Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCurrent ? stepColor : Colors.transparent,
                        border: Border.all(
                          color: stepColor,
                          width: 2.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isCurrent
                              ? _getStatusIcon(stepStatus)
                              : (isCompleted ? Icons.check : Icons.radio_button_unchecked),
                          size: 14,
                          color: isCurrent ? Colors.white : stepColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stepLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent
                            ? AppTheme.getStatusColor(stepStatus)
                            : (isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  ],
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Icons.hourglass_empty;
      case ReportStatus.inProgress:
        return Icons.construction;
      case ReportStatus.solved:
        return Icons.check_circle;
      case ReportStatus.rejected:
        return Icons.cancel;
    }
  }
}
