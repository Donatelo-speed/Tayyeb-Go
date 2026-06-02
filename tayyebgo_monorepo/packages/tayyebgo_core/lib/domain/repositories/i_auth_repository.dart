import '../entities/user.dart';

abstract class IAuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;
  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInWithPhone(String phoneNumber);
  Future<void> signOut();
  Future<AppUser> resolveUser(String firebaseUid);
  Future<void> updateProfile(AppUser user);
}
