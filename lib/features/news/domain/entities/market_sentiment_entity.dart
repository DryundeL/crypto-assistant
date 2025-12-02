class MarketSentimentEntity {
  final String sentimentType; // "bullish", "bearish", "neutral"
  final double percentageUp;
  final double percentageDown;
  final List<String> topGainers;
  final List<String> topLosers;

  const MarketSentimentEntity({
    required this.sentimentType,
    required this.percentageUp,
    required this.percentageDown,
    required this.topGainers,
    required this.topLosers,
  });
}
