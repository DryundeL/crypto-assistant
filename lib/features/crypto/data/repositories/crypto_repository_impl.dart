import '../../domain/entities/crypto_coin_entity.dart';
import '../../domain/entities/recommendation_entity.dart';
import '../../domain/repositories/i_crypto_repository.dart';
import '../datasources/crypto_remote_data_source.dart';

class CryptoRepositoryImpl implements ICryptoRepository {
  final ICryptoRemoteDataSource remoteDataSource;

  CryptoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CryptoCoinEntity>> getTopCoins() async {
    return await remoteDataSource.getTopCoins();
  }

  @override
  Future<RecommendationEntity> getDailyRecommendation(List<CryptoCoinEntity> coins) async {
    return await remoteDataSource.getAiRecommendation(coins);
  }
}
