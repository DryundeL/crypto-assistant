import '../../domain/entities/crypto_coin_entity.dart';
import '../../domain/entities/recommendation_entity.dart';
import '../../domain/repositories/i_crypto_repository.dart';
import '../datasources/crypto_remote_data_source.dart';

class CryptoRepositoryImpl implements ICryptoRepository {
  final ICryptoRemoteDataSource remoteDataSource;

  CryptoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CryptoCoinEntity>> getTopCoins({String currencyCode = 'usd'}) async {
    return await remoteDataSource.getTopCoins(currencyCode: currencyCode);
  }

  @override
  Future<RecommendationEntity> getDailyRecommendation(List<CryptoCoinEntity> coins, String locale) async {
    return await remoteDataSource.getAiRecommendation(coins, locale);
  }

  @override
  Future<List<List<double>>> getMarketChart(String coinId, String period, double currentPrice) async {
    return await remoteDataSource.getMarketChart(coinId, period, currentPrice);
  }
}
