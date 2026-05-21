import 'auth_repository.dart';
import 'report_repository.dart';

class ServiceLocator {
  /// Toggle this boolean to switch the entire application backend.
  /// 
  /// - `false`: Uses local demo mode (persists to SharedPreferences, no setup needed).
  /// - `true`: Connects to real Firebase Auth, Firestore, and Storage.
  static const bool useFirebase = false;

  static final AuthRepository authRepository = MockAuthRepository();

  static final ReportRepository reportRepository = MockReportRepository();
}
