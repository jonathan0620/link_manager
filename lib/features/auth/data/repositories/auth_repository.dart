import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  /// Send verification email for signup
  Future<void> sendVerificationCode({
    required String email,
    required String purpose,
  }) async {
    final callable = _functions.httpsCallable('sendVerificationEmail');
    await callable.call({
      'email': email,
      'purpose': purpose,
    });
  }

  /// Verify the code
  Future<bool> verifyCode({
    required String email,
    required String code,
  }) async {
    final callable = _functions.httpsCallable('verifyCode');
    final result = await callable.call({
      'email': email,
      'code': code,
    });
    return result.data['success'] ?? false;
  }

  /// Sign up with email and password
  Future<UserModel> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    // Check if username is available
    final isAvailable = await isUsernameAvailable(username);
    if (!isAvailable) {
      throw Exception('이미 사용 중인 아이디입니다.');
    }

    // Create Firebase Auth user
    UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('이미 사용 중인 이메일입니다.');
        case 'invalid-email':
          throw Exception('유효하지 않은 이메일 형식입니다.');
        case 'weak-password':
          throw Exception('비밀번호가 너무 약합니다. 6자 이상 입력하세요.');
        default:
          throw Exception('회원가입 실패: ${e.message}');
      }
    }

    final user = credential.user;
    if (user == null) {
      throw Exception('회원가입에 실패했습니다.');
    }

    // Create user document in Firestore
    final userModel = UserModel(
      id: user.uid,
      username: username,
      email: email,
      createdAt: DateTime.now(),
      selectedCategories: [],
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userModel.toFirestore());

    return userModel;
  }

  /// Sign in with username/email and password
  Future<UserModel> signIn({
    required String username,
    required String password,
  }) async {
    String email;

    // Check if input is email or username
    if (username.contains('@')) {
      // Input is email, use directly
      email = username;
    } else {
      // Input is username, find email from Firestore
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('아이디 또는 비밀번호가 올바르지 않습니다.');
      }
      email = query.docs.first.data()['email'] as String;
    }

    // Sign in with email
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception('아이디 또는 비밀번호가 올바르지 않습니다.');
    }

    // Get or create user model
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인에 실패했습니다.');
    }

    // Try to get existing user doc, or create a basic one
    var userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      // Create basic user document
      final newUser = UserModel(
        id: user.uid,
        username: email.split('@')[0],
        email: email,
        createdAt: DateTime.now(),
        selectedCategories: [],
      );
      await _firestore.collection('users').doc(user.uid).set(newUser.toFirestore());
      return newUser;
    }

    return UserModel.fromFirestore(userDoc);
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current user model
  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc);
  }

  /// Find username by email
  Future<String?> findUsernameByEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.data()['username'] as String;
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Update password
  Future<void> updatePassword({
    required String email,
    required String newPassword,
  }) async {
    // Find user by email and sign in to update password
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('사용자를 찾을 수 없습니다.');
    }

    // Update password using admin SDK via Cloud Functions
    final callable = _functions.httpsCallable('updateUserPassword');
    await callable.call({
      'email': email,
      'newPassword': newPassword,
    });
  }

  /// Update selected categories
  Future<void> updateSelectedCategories(List<String> categories) async {
    final user = currentUser;
    if (user == null) throw Exception('로그인이 필요합니다.');

    await _firestore.collection('users').doc(user.uid).update({
      'selectedCategories': categories,
    });
  }
}
