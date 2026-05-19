# Campus Helper: Daily Life Problem Reporter

A premium, high-fidelity mobile application designed for **Pundra University of Science & Technology** (CSE-3102 Course Project). This application allows students to report daily life problems on campus (such as broken equipment, furniture damage, laboratory issues) with image attachment and GPS coordinates. Administrators can track, manage, and update the resolution status of these complaints in real-time.

---

## 📱 Features Implemented

1. **Dual-Role Sign In / Sign Up**:
   - Distinct registration forms for **Students** and **Administrators**.
   - Student registrations require **Student ID** and **Department** selection (e.g., CSE, EEE, Civil).
   - Dynamic landing matching the logged-in user's role.

2. **Complaints Feed & Advanced Filtering**:
   - Real-time search of reported problems.
   - Horizontal category filter chips (Classroom Equipment, Laboratory, Furniture, Restroom, Cafeteria, etc.).
   - Interactive sorting (Priority/Upvotes or Date posted).

3. **GPS Location Capture**:
   - One-tap acquisition of GPS latitude and longitude.
   - Built-in graceful simulation fallback representing **Pundra University** (Bogura campus coordinates: `24.8967, 89.3725`) if running on emulators without location mockers or if permissions are denied.

4. **Interactive Upvote Priority System**:
   - Students can upvote active complaints.
   - Dynamic priority updates to highlight the most critical campus issues instantly.

5. **Visual Lifecycle Tracker (Pending ➔ In Progress ➔ Solved/Rejected)**:
   - Transparent step-by-step progress stepper shown on the problem details screen.

6. **Admin Management Dashboard**:
   - Visual metrics panels summarizing **Pending**, **In Progress**, and **Solved** counts.
   - Status updating modal with resolution notes.

---

## 🛠️ Architecture & Technical Stack

- **Frontend**: Flutter & Dart (Material 3 with bespoke Light & Dark modes).
- **State Management**: Provider (Separation of concern via repository patterns).
- **Backend Architecture**: Decoupled interface supporting both:
  - 💾 **Local Mock Mode (Default)**: Uses local databases (`SharedPreferences`) to store and persist reports, comments, upvotes, and users on-device. No configurations needed!
  - 🔥 **Firebase Production Mode**: Ready-to-go services connecting to `FirebaseAuth`, `Cloud Firestore`, and `Firebase Storage`.

---

## 🚀 Getting Started

### Prerequisites
Make sure you have the Flutter SDK installed on your system.
```bash
flutter doctor
```

### Installation
1. Install package dependencies:
   ```bash
   flutter pub get
   ```

2. Run the application:
   ```bash
   flutter run
   ```

---

## 🧪 Demo Login Credentials (Local Mock Mode)

To make testing and presentation extremely convenient, the login screen includes a **Demo Quick Sign-In** panel:
- **Student Account (Sumon Ahmed)**:
  - **Email**: `student@pundra.edu`
  - **Password**: `password123`
- **Admin Account (Md. Forhan Shahriar Fahim)**:
  - **Email**: `admin@pundra.edu`
  - **Password**: `password123`

---

## 🔥 Connecting to Firebase (For Submission/Production)

Once you are ready to connect the app to your real Firebase project:

### Step 1: Create a Firebase Project
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add Project** and name it `Campus Helper`.

### Step 2: Configure FlutterFire CLI
1. Install Firebase tools globally:
   ```bash
   npm install -g firebase-tools
   ```
2. Log in to Firebase:
   ```bash
   firebase login
   ```
3. Initialize the Flutter configuration inside your project directory:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   *This automatically generates `lib/firebase_options.dart` and links Android/iOS configuration files.*

### Step 3: Switch Backend Toggle
Open [lib/repositories/service_locator.dart](file:///e:/Project/lib/repositories/service_locator.dart) and set `useFirebase` to `true`:

```dart
class ServiceLocator {
  // SET THIS TO TRUE TO ENABLE FIREBASE
  static const bool useFirebase = true; 
  ...
}
```

### Step 4: Configure Database Rules
Ensure your Cloud Firestore rules allow authenticated users to read and write:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```
And set Firebase Storage rules:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```
