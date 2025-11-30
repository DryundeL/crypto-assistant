import 'crypto_coin_entity.dart';
import 'recommendation_entity.dart';

abstract class ICryptoRepository {
  Future<List<CryptoCoinEntity>> getTopCoins();
  Future<RecommendationEntity> getDailyRecommendation(List<CryptoCoinEntity> coins);
}
