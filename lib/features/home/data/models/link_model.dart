import 'package:cloud_firestore/cloud_firestore.dart';

class LinkModel {
  final String id;
  final String userId;
  final String url;
  final String title;
  final String? thumbnailUrl;
  final String? label;
  final bool isRead;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LinkModel({
    required this.id,
    required this.userId,
    required this.url,
    required this.title,
    this.thumbnailUrl,
    this.label,
    this.isRead = false,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LinkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LinkModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      url: data['url'] ?? '',
      title: data['title'] ?? '제목 없음',
      thumbnailUrl: data['thumbnailUrl'],
      label: data['label'],
      isRead: data['isRead'] ?? false,
      isFavorite: data['isFavorite'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'url': url,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'label': label,
      'isRead': isRead,
      'isFavorite': isFavorite,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  LinkModel copyWith({
    String? id,
    String? userId,
    String? url,
    String? title,
    String? thumbnailUrl,
    String? label,
    bool? isRead,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LinkModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      url: url ?? this.url,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      label: label ?? this.label,
      isRead: isRead ?? this.isRead,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get domain from URL
  String get domain {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return uri.host;
    } catch (e) {
      return url;
    }
  }

  @override
  String toString() {
    return 'LinkModel(id: $id, title: $title, url: $url)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LinkModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
