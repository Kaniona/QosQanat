import 'enums.dart';

/// Жаңалық (offline режімде seed-тен, болашақта админ жариялайды).
class News {
  const News({
    required this.id,
    required this.category,
    required this.title,
    required this.preview,
    required this.publishedAt,
    this.hasCover = false,
    this.body = '',
  });

  final String id;
  final NewsCategory category;
  final String title;
  final String preview;
  final DateTime publishedAt;

  /// Cover суреті бар ма (16:9 плейсхолдер көрсетіледі).
  final bool hasCover;
  final String body;

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'title': title,
        'preview': preview,
        'published_at': publishedAt.toIso8601String(),
        'has_cover': hasCover,
        'body': body,
      };

  factory News.fromJson(Map<String, dynamic> json) => News(
        id: json['id'] as String,
        category: NewsCategory.fromName(json['category'] as String?),
        title: json['title'] as String? ?? '',
        preview: json['preview'] as String? ?? '',
        publishedAt:
            DateTime.tryParse(json['published_at'] as String? ?? '') ??
                DateTime.now(),
        hasCover: json['has_cover'] as bool? ?? false,
        body: json['body'] as String? ?? '',
      );
}
