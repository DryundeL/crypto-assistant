import 'package:flutter/material.dart';
import '../../domain/entities/news_article_entity.dart';
import '../../domain/entities/market_sentiment_entity.dart';
import '../../domain/repositories/i_news_repository.dart';

class NewsViewModel extends ChangeNotifier {
  final INewsRepository repository;
  final String locale;

  NewsViewModel({required this.repository, required this.locale}) {
    loadNews();
  }

  List<NewsArticleEntity> _allNews = [];
  MarketSentimentEntity? _sentiment;
  bool _isLoading = false;
  String? _error;

  List<NewsArticleEntity> get news => _allNews;
  List<NewsArticleEntity> get bullishNews =>
      _allNews.where((n) => n.isBullish).toList();
  List<NewsArticleEntity> get bearishNews =>
      _allNews.where((n) => !n.isBullish).toList();
  MarketSentimentEntity? get sentiment => _sentiment;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNews() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allNews = await repository.getNews(locale);
      _sentiment = await repository.getMarketSentiment();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadNews();
  }
}
