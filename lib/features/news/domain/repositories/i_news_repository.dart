import '../entities/news_article_entity.dart';
import '../entities/market_sentiment_entity.dart';

abstract class INewsRepository {
  Future<List<NewsArticleEntity>> getNews(String locale);
  Future<MarketSentimentEntity> getMarketSentiment();
}
