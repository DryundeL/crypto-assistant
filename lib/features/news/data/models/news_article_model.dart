import '../../domain/entities/news_article_entity.dart';

class NewsArticleModel extends NewsArticleEntity {
  const NewsArticleModel({
    required super.id,
    required super.title,
    required super.summary,
    required super.expertName,
    required super.expertCredentials,
    required super.prediction,
    required super.timestamp,
    required super.source,
    required super.isBullish,
  });

  factory NewsArticleModel.fromJson(Map<String, dynamic> json) {
    return NewsArticleModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      expertName: json['expert_name'] ?? '',
      expertCredentials: json['expert_credentials'] ?? '',
      prediction: json['prediction'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      source: json['source'] ?? '',
      isBullish: json['is_bullish'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'expert_name': expertName,
      'expert_credentials': expertCredentials,
      'prediction': prediction,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'is_bullish': isBullish,
    };
  }
}
