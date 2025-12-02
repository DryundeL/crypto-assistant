class NewsArticleEntity {
  final String id;
  final String title;
  final String summary;
  final String expertName;
  final String expertCredentials;
  final String prediction; // "bullish" or "bearish"
  final DateTime timestamp;
  final String source;
  final bool isBullish;

  const NewsArticleEntity({
    required this.id,
    required this.title,
    required this.summary,
    required this.expertName,
    required this.expertCredentials,
    required this.prediction,
    required this.timestamp,
    required this.source,
    required this.isBullish,
  });
}
