# Campus Helper (Daily Life Problem Reporter)

## Introduction
Campus Helper is a centralized mobile application designed for university students to report daily campus problems (e.g., broken projectors, AC leaks, damaged furniture). Students can report issues with categories, descriptions, and locations. Administrators can manage these reports and update their resolution status digitally.

## Key Features

### For Students:
- **Submit Reports:** Create new problem reports with a title, description, and category.
- **Real-time Tracking:** See the status of reports (Pending → In Progress → Solved).
- **Upvote Priority:** Upvote issues to highlight urgency to administrators.
- **My Profile & Activities:** View, edit, or delete personal reports. Edit personal profile information securely.

### For Administrators:
- **Admin Dashboard:** View and manage all reports submitted across the campus.
- **Status Updates:** Update issue statuses and leave admin notes (e.g., "Technician scheduled for Wednesday").
- **User Management:** View all registered students and admins. Edit student details or remove accounts if necessary.
- **Add Admins:** Securely add new administrators to the system.

## Technology Stack
- **Framework:** Flutter (Dart)
- **State Management:** Provider
- **Storage:** Local Storage (`SharedPreferences`) used as a Mock Database for rapid testing without Firebase dependency.

## Getting Started

1. **Prerequisites:** Make sure you have the Flutter SDK installed.
2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```
3. **Run the App:**
   ```bash
   flutter run
   ```

## Demo Accounts
To test the app locally, you can register a new account on the Sign Up screen as a Student. Admins must be added through the Admin panel by an existing Administrator.
