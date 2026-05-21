import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final users = await authProvider.fetchAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  void _showEditDialog(UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final studentIdController = TextEditingController(text: user.studentId);
    final departmentController = TextEditingController(text: user.department);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit User'),
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
                  // Email is read-only
                  TextFormField(
                    initialValue: user.email,
                    decoration: const InputDecoration(labelText: 'Email Address'),
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  if (user.role == UserRole.student) ...[
                    TextFormField(
                      controller: studentIdController,
                      decoration: const InputDecoration(labelText: 'Student ID'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: departmentController,
                      decoration: const InputDecoration(labelText: 'Department'),
                    ),
                  ],
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
                    email: user.email,
                    studentId: user.role == UserRole.student ? studentIdController.text.trim() : '',
                    department: user.role == UserRole.student ? departmentController.text.trim() : '',
                    role: user.role, // role cannot be changed
                  );

                  Navigator.pop(context); // Close dialog

                  final success = await authProvider.updateUser(updatedUser);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'User updated successfully' : (authProvider.errorMessage ?? 'Update failed')),
                        backgroundColor: success ? AppTheme.solvedColor : AppTheme.rejectedColor,
                      ),
                    );
                    if (success) {
                      _loadUsers();
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User?'),
          content: Text('Are you sure you want to permanently delete ${user.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rejectedColor),
              onPressed: () async {
                Navigator.pop(context); // close dialog
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final success = await authProvider.deleteUser(user.email);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'User deleted' : (authProvider.errorMessage ?? 'Deletion failed')),
                      backgroundColor: success ? AppTheme.solvedColor : AppTheme.rejectedColor,
                    ),
                  );
                  if (success) {
                    _loadUsers();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _users.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = _users[index];
                final isAdmin = user.role == UserRole.admin;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAdmin ? AppTheme.accentColor.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.2),
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: isAdmin ? AppTheme.accentColor : AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${user.email}${isAdmin ? '' : ' • ${user.department} • ${user.studentId}'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () => _showEditDialog(user),
                        tooltip: 'Edit User',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDeleteUser(user),
                        tooltip: 'Delete User',
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
