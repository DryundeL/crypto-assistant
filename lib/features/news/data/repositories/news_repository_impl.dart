import '../../domain/entities/news_article_entity.dart';
import '../../domain/entities/market_sentiment_entity.dart';
import '../../domain/repositories/i_news_repository.dart';
import '../datasources/news_remote_data_source.dart';
import '../../../crypto/domain/entities/crypto_coin_entity.dart';

class NewsRepositoryImpl implements INewsRepository {
  final INewsRemoteDataSource remoteDataSource;
  List<CryptoCoinEntity> _coins = [];

  NewsRepositoryImpl({
    required this.remoteDataSource,
  });

  void updateCoins(List<CryptoCoinEntity> coins) {
    _coins = coins;
  }

  @override
  Future<List<NewsArticleEntity>> getNews(String locale) async {
    return await remoteDataSource.getNews(locale, _coins);
  }

  @override
  Future<MarketSentimentEntity> getMarketSentiment() async {
    return await remoteDataSource.getMarketSentiment(_coins);
  }
}
