import '../entities/crypto_coin_entity.dart';
import '../entities/recommendation_entity.dart';

abstract class ICryptoRepository {
  Future<List<CryptoCoinEntity>> getTopCoins({String currencyCode = 'usd'});
  Future<List<List<double>>> getMarketChart(String coinId, String period, double currentPrice, String currencyCode);
  Future<CryptoCoinEntity> getCoinDetails(String id);
  Future<double?> getCoinPriceAtDate(String coinId, String symbol, DateTime date, String currencyCode);
  Future<RecommendationEntity> getDailyRecommendation(List<CryptoCoinEntity> coins, String locale);
}
