import 'crypto_coin_entity.dart';

class RecommendationEntity {
  final CryptoCoinEntity coin;
  final String reason;
  final double confidenceScore;
  final String whaleActivitySummary;

  final String tradingVolume24h;
  final double change1W;
  final double change1M;
  final double change1Y;
  final String prediction;
  final String analysisDetails;

  const RecommendationEntity({
    required this.coin,
    required this.reason,
    required this.confidenceScore,
    required this.whaleActivitySummary,
    required this.tradingVolume24h,
    required this.change1W,
    required this.change1M,
    required this.change1Y,
    required this.prediction,
    required this.analysisDetails,
  });
}
