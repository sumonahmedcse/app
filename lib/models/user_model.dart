enum UserRole {
  student,
  admin,
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String studentId; // Empty for admins
  final String department; // Empty for admins
  final UserRole role;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.studentId,
    required this.department,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'studentId': studentId,
      'department': department,
      'role': role.toString().split('.').last,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      studentId: map['studentId'] ?? '',
      department: map['department'] ?? '',
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.student,
    );
  }
}
