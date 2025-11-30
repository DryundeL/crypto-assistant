import 'crypto_coin_entity.dart';

class RecommendationEntity {
  final CryptoCoinEntity coin;
  final String reason;
  final double confidenceScore;
  final String whaleActivitySummary;

  const RecommendationEntity({
    required this.coin,
    required this.reason,
    required this.confidenceScore,
    required this.whaleActivitySummary,
  });
}
