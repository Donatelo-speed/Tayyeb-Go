import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_prod.dart';
import 'firebase_options_staging.dart';
import 'firebase_options_dev.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Select environment via --dart-define=ENV=dev|staging|prod
    // Defaults to prod if not specified.
    const env = String.fromEnvironment('ENV', defaultValue: 'prod');
    switch (env) {
      case 'dev':
        return DevFirebaseOptions.currentPlatform;
      case 'staging':
        return StagingFirebaseOptions.currentPlatform;
      case 'prod':
      default:
        return ProdFirebaseOptions.currentPlatform;
    }
  }
}
