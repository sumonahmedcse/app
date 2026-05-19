import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../models/report_model.dart';
import '../theme/app_theme.dart';
import '../widgets/report_card.dart';
import 'login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _searchController = TextEditingController();
  ReportStatus? _selectedStatusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final reportProvider = Provider.of<ReportProvider>(context);
    final user = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter reports based on tabs
    final reportsList = reportProvider.reports;
    if (_selectedStatusFilter != null) {
      reportsList.retainWhere((r) => r.status == _selectedStatusFilter);
    }

    // Admins want issues sorted by Upvotes (priority) by default, then date
    reportsList.sort((a, b) {
      int upvoteCompare = b.upvotesCount.compareTo(a.upvotesCount);
      if (upvoteCompare != 0) return upvoteCompare;
      return b.reportedAt.compareTo(a.reportedAt);
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Admin Dashboard'),
            if (user != null)
              Text(
                'Welcome, ${user.name}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: _handleLogout,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Panel Grid
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Pending',
                    count: reportProvider.pendingReportsCount,
                    color: AppTheme.pendingColor,
                    icon: Icons.hourglass_empty,
                    isSelected: _selectedStatusFilter == ReportStatus.pending,
                    onTap: () {
                      setState(() {
                        if (_selectedStatusFilter == ReportStatus.pending) {
                          _selectedStatusFilter = null;
                        } else {
                          _selectedStatusFilter = ReportStatus.pending;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'In Progress',
                    count: reportProvider.inProgressReportsCount,
                    color: AppTheme.inProgressColor,
                    icon: Icons.construction,
                    isSelected: _selectedStatusFilter == ReportStatus.inProgress,
                    onTap: () {
                      setState(() {
                        if (_selectedStatusFilter == ReportStatus.inProgress) {
                          _selectedStatusFilter = null;
                        } else {
                          _selectedStatusFilter = ReportStatus.inProgress;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Solved',
                    count: reportProvider.solvedReportsCount,
                    color: AppTheme.solvedColor,
                    icon: Icons.check_circle_outline,
                    isSelected: _selectedStatusFilter == ReportStatus.solved,
                    onTap: () {
                      setState(() {
                        if (_selectedStatusFilter == ReportStatus.solved) {
                          _selectedStatusFilter = null;
                        } else {
                          _selectedStatusFilter = ReportStatus.solved;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search complaints by title, details...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          reportProvider.setSearchQuery('');
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (query) {
                reportProvider.setSearchQuery(query);
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedStatusFilter == null
                      ? 'All High-Priority Issues'
                      : 'Filtered ${_selectedStatusFilter!.displayName} Issues',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${reportsList.length} items',
                  style: TextStyle(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Admin Reports Feed
          Expanded(
            child: reportProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : reportsList.isEmpty
                    ? _buildEmptyState(context, isDark)
                    : RefreshIndicator(
                        onRefresh: () => reportProvider.fetchReports(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: reportsList.length,
                          itemBuilder: (context, index) {
                            return ReportCard(report: reportsList[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : (isDark ? AppTheme.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppTheme.borderDark : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withOpacity(0.1) : Colors.black.withOpacity(0.01),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_rtl_outlined,
              size: 72,
              color: Colors.grey.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Reports Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'There are no reports matching this lifecycle status.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
