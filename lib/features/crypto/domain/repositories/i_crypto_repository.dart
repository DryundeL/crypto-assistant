import '../entities/crypto_coin_entity.dart';
import '../entities/recommendation_entity.dart';

abstract class ICryptoRepository {
  Future<List<CryptoCoinEntity>> getTopCoins();
  Future<RecommendationEntity> getDailyRecommendation(List<CryptoCoinEntity> coins, String locale);
  Future<List<List<double>>> getMarketChart(String coinId, String period, double currentPrice);
}
