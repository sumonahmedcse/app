import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';
import '../theme/app_theme.dart';
import '../widgets/report_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showEditProfileDialog(UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email Address'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: currentPasswordController,
                    decoration: const InputDecoration(labelText: 'Current Password (Required)'),
                    obscureText: true,
                    validator: (val) => val == null || val.isEmpty ? 'Required to save changes' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'New Password (Optional)',
                      hintText: 'Leave blank to keep current',
                    ),
                    obscureText: true,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  
                  final updatedUser = UserModel(
                    uid: user.uid,
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    studentId: user.studentId,
                    department: user.department,
                    role: user.role,
                  );

                  Navigator.pop(context); // Close dialog

                  final success = await authProvider.updateProfile(
                    oldEmail: user.email,
                    updatedUser: updatedUser,
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text.isNotEmpty ? newPasswordController.text : null,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Profile updated successfully' : (authProvider.errorMessage ?? 'Update failed')),
                        backgroundColor: success ? AppTheme.solvedColor : AppTheme.rejectedColor,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _showEditReportDialog(ReportModel report) {
    final titleController = TextEditingController(text: report.title);
    final descController = TextEditingController(text: report.description);
    String selectedCategory = report.category;
    final formKey = GlobalKey<FormState>();

    final categories = ['Classroom Equipment', 'Laboratory', 'Furniture', 'Cleanliness', 'Security', 'Other'];
    if (!categories.contains(selectedCategory)) {
      categories.add(selectedCategory);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: const Text('Edit Report'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setStateSB(() => selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
                      
                      final updatedReport = report.copyWith(
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        category: selectedCategory,
                      );

                      Navigator.pop(context); // close dialog

                      final success = await reportProvider.updateReport(updatedReport);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Report updated' : (reportProvider.errorMessage ?? 'Update failed')),
                            backgroundColor: success ? AppTheme.solvedColor : AppTheme.rejectedColor,
                          ),
                        );
                        if (success) {
                          reportProvider.fetchReports(); // Refresh the list
                        }
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _confirmDeleteReport(ReportModel report) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Report?'),
          content: const Text('Are you sure you want to permanently delete this report?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rejectedColor),
              onPressed: () async {
                Navigator.pop(context); // close dialog
                final reportProvider = Provider.of<ReportProvider>(context, listen: false);
                final success = await reportProvider.deleteReport(report.id);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Report deleted' : (reportProvider.errorMessage ?? 'Deletion failed')),
                      backgroundColor: success ? AppTheme.solvedColor : AppTheme.rejectedColor,
                    ),
                  );
                  if (success) {
                    reportProvider.fetchReports();
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final reportProvider = Provider.of<ReportProvider>(context);
    final user = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    // Filter reports belonging to this user
    final userReports = reportProvider.reports.where((r) => r.reportedBy == user.uid).toList();
    
    // Sort by date descending
    userReports.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: Column(
        children: [
          // Profile Details Section
          Container(
            padding: const EdgeInsets.all(24.0),
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: user.role == UserRole.admin 
                      ? AppTheme.accentColor.withOpacity(0.2) 
                      : AppTheme.primaryColor.withOpacity(0.2),
                  child: Icon(
                    user.role == UserRole.admin ? Icons.admin_panel_settings : Icons.person,
                    size: 40,
                    color: user.role == UserRole.admin ? AppTheme.accentColor : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                ),
                if (user.role == UserRole.student) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${user.department} • ID: ${user.studentId}',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _showEditProfileDialog(user),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Activity Section Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Activities (${userReports.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          // Reports List
          Expanded(
            child: userReports.isEmpty
                ? Center(
                    child: Text(
                      'You have not submitted any reports yet.',
                      style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: userReports.length,
                    itemBuilder: (context, index) {
                      final report = userReports[index];
                      return Stack(
                        children: [
                          ReportCard(report: report),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_note, color: Colors.blue),
                                  onPressed: () => _showEditReportDialog(report),
                                  tooltip: 'Edit Report',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _confirmDeleteReport(report),
                                  tooltip: 'Delete Report',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
