import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';
import '../models/link_model.dart';

class LinkRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  LinkRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _linksCollection =>
      _firestore.collection('links');

  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      _firestore.collection('categories');

  // ========== Links ==========

  /// Get all links for current user
  Stream<List<LinkModel>> getLinksStream() {
    if (_userId == null) return Stream.value([]);

    return _linksCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => LinkModel.fromFirestore(doc)).toList());
  }

  /// Get recent links (last 10)
  Stream<List<LinkModel>> getRecentLinksStream({int limit = 10}) {
    if (_userId == null) return Stream.value([]);

    return _linksCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => LinkModel.fromFirestore(doc)).toList());
  }

  /// Get unread links
  Stream<List<LinkModel>> getUnreadLinksStream() {
    if (_userId == null) return Stream.value([]);

    return _linksCollection
        .where('userId', isEqualTo: _userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => LinkModel.fromFirestore(doc)).toList());
  }

  /// Get links by label
  Stream<List<LinkModel>> getLinksByLabelStream(String label) {
    if (_userId == null) return Stream.value([]);

    return _linksCollection
        .where('userId', isEqualTo: _userId)
        .where('label', isEqualTo: label)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => LinkModel.fromFirestore(doc)).toList());
  }

  /// Get link by ID
  Future<LinkModel?> getLinkById(String linkId) async {
    final doc = await _linksCollection.doc(linkId).get();
    if (!doc.exists) return null;
    return LinkModel.fromFirestore(doc);
  }

  /// Add new link
  Future<LinkModel> addLink({
    required String url,
    required String title,
    String? thumbnailUrl,
    String? label,
  }) async {
    if (_userId == null) throw Exception('로그인이 필요합니다.');

    final now = DateTime.now();
    final docRef = _linksCollection.doc();

    final link = LinkModel(
      id: docRef.id,
      userId: _userId!,
      url: url,
      title: title.isEmpty ? '제목 없음' : title,
      thumbnailUrl: thumbnailUrl,
      label: label,
      isRead: false,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(link.toFirestore());

    // Update category link count if label exists
    if (label != null && label.isNotEmpty) {
      await _incrementCategoryLinkCount(label);
    }

    return link;
  }

  /// Update link
  Future<void> updateLink({
    required String linkId,
    String? url,
    String? title,
    String? thumbnailUrl,
    String? label,
    bool? isRead,
  }) async {
    final existingLink = await getLinkById(linkId);
    if (existingLink == null) throw Exception('링크를 찾을 수 없습니다.');

    final updates = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (url != null) updates['url'] = url;
    if (title != null) updates['title'] = title;
    if (thumbnailUrl != null) updates['thumbnailUrl'] = thumbnailUrl;
    if (label != null) updates['label'] = label;
    if (isRead != null) updates['isRead'] = isRead;

    await _linksCollection.doc(linkId).update(updates);

    // Update category link counts if label changed
    if (label != null && label != existingLink.label) {
      if (existingLink.label != null && existingLink.label!.isNotEmpty) {
        await _decrementCategoryLinkCount(existingLink.label!);
      }
      if (label.isNotEmpty) {
        await _incrementCategoryLinkCount(label);
      }
    }
  }

  /// Delete link
  Future<void> deleteLink(String linkId) async {
    final link = await getLinkById(linkId);
    if (link == null) return;

    await _linksCollection.doc(linkId).delete();

    // Update category link count
    if (link.label != null && link.label!.isNotEmpty) {
      await _decrementCategoryLinkCount(link.label!);
    }
  }

  /// Mark link as read
  Future<void> markAsRead(String linkId) async {
    await _linksCollection.doc(linkId).update({
      'isRead': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Search links by title or URL
  Future<List<LinkModel>> searchLinks(String query) async {
    if (_userId == null) return [];
    if (query.isEmpty) return [];

    // Firestore doesn't support full-text search natively
    // We'll fetch all user's links and filter locally
    final snapshot = await _linksCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .get();

    final links = snapshot.docs.map((doc) => LinkModel.fromFirestore(doc)).toList();
    final lowerQuery = query.toLowerCase();

    return links
        .where((link) =>
            link.title.toLowerCase().contains(lowerQuery) ||
            link.url.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // ========== Categories ==========

  /// Get all categories for current user
  Stream<List<CategoryModel>> getCategoriesStream() {
    if (_userId == null) return Stream.value([]);

    return _categoriesCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc))
            .toList());
  }

  /// Get all unique labels from user's links
  Future<List<String>> getUniqueLabels() async {
    if (_userId == null) return [];

    final snapshot = await _linksCollection
        .where('userId', isEqualTo: _userId)
        .get();

    final labels = <String>{};
    for (final doc in snapshot.docs) {
      final label = doc.data()['label'] as String?;
      if (label != null && label.isNotEmpty) {
        labels.add(label);
      }
    }

    return labels.toList()..sort();
  }

  /// Add category
  Future<CategoryModel> addCategory(String name) async {
    if (_userId == null) throw Exception('로그인이 필요합니다.');

    final docRef = _categoriesCollection.doc();
    final category = CategoryModel(
      id: docRef.id,
      userId: _userId!,
      name: name,
      linkCount: 0,
      createdAt: DateTime.now(),
    );

    await docRef.set(category.toFirestore());
    return category;
  }

  /// Delete category
  Future<void> deleteCategory(String categoryId) async {
    await _categoriesCollection.doc(categoryId).delete();
  }

  /// Increment category link count
  Future<void> _incrementCategoryLinkCount(String categoryName) async {
    if (_userId == null) return;

    final snapshot = await _categoriesCollection
        .where('userId', isEqualTo: _userId)
        .where('name', isEqualTo: categoryName)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({
        'linkCount': FieldValue.increment(1),
      });
    } else {
      // Create category if it doesn't exist
      await addCategory(categoryName);
      final newSnapshot = await _categoriesCollection
          .where('userId', isEqualTo: _userId)
          .where('name', isEqualTo: categoryName)
          .limit(1)
          .get();
      if (newSnapshot.docs.isNotEmpty) {
        await newSnapshot.docs.first.reference.update({
          'linkCount': 1,
        });
      }
    }
  }

  /// Decrement category link count
  Future<void> _decrementCategoryLinkCount(String categoryName) async {
    if (_userId == null) return;

    final snapshot = await _categoriesCollection
        .where('userId', isEqualTo: _userId)
        .where('name', isEqualTo: categoryName)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final currentCount = snapshot.docs.first.data()['linkCount'] ?? 0;
      await snapshot.docs.first.reference.update({
        'linkCount': currentCount > 0 ? FieldValue.increment(-1) : 0,
      });
    }
  }

  /// Get link count by label
  Future<int> getLinkCountByLabel(String label) async {
    if (_userId == null) return 0;

    final snapshot = await _linksCollection
        .where('userId', isEqualTo: _userId)
        .where('label', isEqualTo: label)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Get total link count
  Future<int> getTotalLinkCount() async {
    if (_userId == null) return 0;

    final snapshot = await _linksCollection
        .where('userId', isEqualTo: _userId)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Get unread link count
  Future<int> getUnreadLinkCount() async {
    if (_userId == null) return 0;

    final snapshot = await _linksCollection
        .where('userId', isEqualTo: _userId)
        .where('isRead', isEqualTo: false)
        .count()
        .get();

    return snapshot.count ?? 0;
  }
}
