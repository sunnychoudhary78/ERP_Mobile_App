class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final String? type;
  final Map<String, dynamic>? meta;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.type,
    this.meta,
    this.createdAt,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      type: type,
      meta: meta,
      createdAt: createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ??
          json['subject']?.toString() ??
          'Notification',
      body: json['body']?.toString() ??
          json['message']?.toString() ??
          '',
      isRead: json['is_read'] == true || json['isRead'] == true,
      type: json['type']?.toString(),
      meta: json['meta'] is Map
          ? Map<String, dynamic>.from(json['meta'] as Map)
          : json['data'] is Map
              ? Map<String, dynamic>.from(json['data'] as Map)
              : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
    );
  }
}
