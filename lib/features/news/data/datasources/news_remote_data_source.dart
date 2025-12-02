import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/entities/news_article_entity.dart';
import '../../domain/entities/market_sentiment_entity.dart';
import '../models/news_article_model.dart';
import '../../../crypto/domain/entities/crypto_coin_entity.dart';

abstract class INewsRemoteDataSource {
  Future<List<NewsArticleModel>> getNews(String locale, List<CryptoCoinEntity> coins);
  Future<MarketSentimentEntity> getMarketSentiment(List<CryptoCoinEntity> coins);
}

class NewsRemoteDataSource implements INewsRemoteDataSource {
  final http.Client client;
  final Random _random = Random();
  static const String _baseUrl = 'https://cryptopanic.com/api/v1';

  NewsRemoteDataSource({http.Client? client}) : client = client ?? http.Client();

  String? get _apiKey => dotenv.env['CRYPTOPANIC_API_KEY'];

  @override
  Future<MarketSentimentEntity> getMarketSentiment(List<CryptoCoinEntity> coins) async {
    if (coins.isEmpty) {
      return const MarketSentimentEntity(
        sentimentType: 'neutral',
        percentageUp: 50.0,
        percentageDown: 50.0,
        topGainers: [],
        topLosers: [],
      );
    }

    final coinsUp = coins.where((c) => c.priceChangePercentage24h > 0).length;
    final coinsDown = coins.where((c) => c.priceChangePercentage24h < 0).length;
    final total = coins.length;

    final percentageUp = (coinsUp / total) * 100;
    final percentageDown = (coinsDown / total) * 100;

    String sentimentType;
    if (percentageUp > 60) {
      sentimentType = 'bullish';
    } else if (percentageDown > 60) {
      sentimentType = 'bearish';
    } else {
      sentimentType = 'neutral';
    }

    final sortedByGain = List<CryptoCoinEntity>.from(coins)
      ..sort((a, b) => b.priceChangePercentage24h.compareTo(a.priceChangePercentage24h));

    final topGainers = sortedByGain.take(3).map((c) => c.name).toList();
    final topLosers = sortedByGain.reversed.take(3).map((c) => c.name).toList();

    return MarketSentimentEntity(
      sentimentType: sentimentType,
      percentageUp: percentageUp,
      percentageDown: percentageDown,
      topGainers: topGainers,
      topLosers: topLosers,
    );
  }

  @override
  Future<List<NewsArticleModel>> getNews(String locale, List<CryptoCoinEntity> coins) async {
    // If API key is available, fetch real news
    if (_apiKey != null && _apiKey!.isNotEmpty && _apiKey != 'your_api_key_here') {
      try {
        return await _fetchRealNews(locale);
      } catch (e) {
        print('Failed to fetch real news: $e');
        print('Falling back to mock news');
        // Fall back to mock news if API fails
      }
    }

    // Use mock news if no API key or API fails
    await Future.delayed(const Duration(milliseconds: 500));
    final sentiment = await getMarketSentiment(coins);
    final news = <NewsArticleModel>[];
    news.addAll(_generateBullishNews(locale, sentiment));
    news.addAll(_generateBearishNews(locale, sentiment));
    return news;
  }

  Future<List<NewsArticleModel>> _fetchRealNews(String locale) async {
    final news = <NewsArticleModel>[];
    
    // Fetch bullish news
    final bullishUrl = '$_baseUrl/posts/?auth_token=$_apiKey&public=true&kind=news&filter=rising&currencies=BTC,ETH';
    final bullishResponse = await client.get(Uri.parse(bullishUrl));
    
    if (bullishResponse.statusCode == 200) {
      final data = json.decode(bullishResponse.body);
      final results = data['results'] as List;
      
      for (var item in results.take(3)) {
        final votes = item['votes'] ?? {};
        final positive = votes['positive'] ?? 0;
        final negative = votes['negative'] ?? 0;
        final isBullish = positive > negative;
        
        final title = item['title'] ?? '';
        final summary = _extractSummary(item);
        
        // Translate if Russian locale
        final translatedTitle = locale == 'ru' ? await _translateText(title) : title;
        final translatedSummary = locale == 'ru' ? await _translateText(summary) : summary;
        
        news.add(NewsArticleModel(
          id: item['id'].toString(),
          title: translatedTitle,
          summary: translatedSummary,
          expertName: _extractExpertName(item, locale),
          expertCredentials: _extractExpertCredentials(item, locale),
          prediction: _generatePrediction(isBullish, locale),
          timestamp: DateTime.parse(item['published_at'] ?? DateTime.now().toIso8601String()),
          source: item['source']?['title'] ?? 'CryptoPanic',
          isBullish: isBullish,
        ));
      }
    }
    
    // Fetch bearish/important news
    final bearishUrl = '$_baseUrl/posts/?auth_token=$_apiKey&public=true&kind=news&filter=important';
    final bearishResponse = await client.get(Uri.parse(bearishUrl));
    
    if (bearishResponse.statusCode == 200) {
      final data = json.decode(bearishResponse.body);
      final results = data['results'] as List;
      
      for (var item in results.take(3)) {
        final votes = item['votes'] ?? {};
        final positive = votes['positive'] ?? 0;
        final negative = votes['negative'] ?? 0;
        final isBullish = positive > negative;
        
        // Only add if not already added
        if (!news.any((n) => n.id == item['id'].toString())) {
          final title = item['title'] ?? '';
          final summary = _extractSummary(item);
          
          // Translate if Russian locale
          final translatedTitle = locale == 'ru' ? await _translateText(title) : title;
          final translatedSummary = locale == 'ru' ? await _translateText(summary) : summary;
          
          news.add(NewsArticleModel(
            id: item['id'].toString(),
            title: translatedTitle,
            summary: translatedSummary,
            expertName: _extractExpertName(item, locale),
            expertCredentials: _extractExpertCredentials(item, locale),
            prediction: _generatePrediction(isBullish, locale),
            timestamp: DateTime.parse(item['published_at'] ?? DateTime.now().toIso8601String()),
            source: item['source']?['title'] ?? 'CryptoPanic',
            isBullish: isBullish,
          ));
        }
      }
    }
    
    return news;
  }

  Future<String> _translateText(String text) async {
    if (text.isEmpty) return text;
    
    try {
      // MyMemory Translation API (free, no registration needed)
      final url = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=en|ru'
      );
      
      final response = await client.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translatedText = data['responseData']?['translatedText'];
        
        if (translatedText != null && translatedText.isNotEmpty) {
          return translatedText;
        }
      }
    } catch (e) {
      print('Translation failed: $e');
    }
    
    // Return original text if translation fails
    return text;
  }

  String _extractSummary(Map<String, dynamic> item) {
    // Try to get summary from metadata or use title
    final metadata = item['metadata'] ?? {};
    return metadata['description'] ?? item['title'] ?? '';
  }

  String _extractExpertName(Map<String, dynamic> item, String locale) {
    final source = item['source'] ?? {};
    final domain = source['domain'] ?? '';
    
    // Map known sources to expert names
    final expertMapEn = {
      'coindesk.com': 'CoinDesk Editorial Team',
      'cointelegraph.com': 'Cointelegraph Analysts',
      'bloomberg.com': 'Bloomberg Crypto',
      'twitter.com': 'Crypto Twitter',
      'reddit.com': 'Reddit Community',
    };
    
    final expertMapRu = {
      'coindesk.com': 'Редакция CoinDesk',
      'cointelegraph.com': 'Аналитики Cointelegraph',
      'bloomberg.com': 'Bloomberg Crypto',
      'twitter.com': 'Crypto Twitter',
      'reddit.com': 'Сообщество Reddit',
    };
    
    final expertMap = locale == 'ru' ? expertMapRu : expertMapEn;
    return expertMap[domain] ?? source['title'] ?? (locale == 'ru' ? 'Крипто Эксперт' : 'Crypto Expert');
  }

  String _extractExpertCredentials(Map<String, dynamic> item, String locale) {
    final source = item['source'] ?? {};
    final domain = source['domain'] ?? '';
    
    final credentialsMapEn = {
      'coindesk.com': 'Leading Crypto News Platform',
      'cointelegraph.com': 'Global Blockchain News',
      'bloomberg.com': 'Financial News & Analysis',
      'twitter.com': 'Social Media Insights',
      'reddit.com': 'Community Analysis',
    };
    
    final credentialsMapRu = {
      'coindesk.com': 'Ведущая крипто-новостная платформа',
      'cointelegraph.com': 'Глобальные блокчейн новости',
      'bloomberg.com': 'Финансовые новости и аналитика',
      'twitter.com': 'Аналитика соцсетей',
      'reddit.com': 'Анализ сообщества',
    };
    
    final credentialsMap = locale == 'ru' ? credentialsMapRu : credentialsMapEn;
    return credentialsMap[domain] ?? (locale == 'ru' ? 'Источник крипто-новостей' : 'Crypto News Source');
  }

  String _generatePrediction(bool isBullish, String locale) {
    if (locale == 'ru') {
      return isBullish 
        ? 'Позитивный тренд, ожидается рост'
        : 'Осторожность, возможна коррекция';
    } else {
      return isBullish
        ? 'Positive trend, growth expected'
        : 'Caution advised, correction possible';
    }
  }

  // Mock news generation (fallback)
  List<NewsArticleModel> _generateBullishNews(String locale, MarketSentimentEntity sentiment) {
    final now = DateTime.now();
    final news = <NewsArticleModel>[];

    if (locale == 'ru') {
      news.addAll([
        NewsArticleModel(
          id: 'bull_1',
          title: 'Институциональные инвесторы увеличивают позиции в криптовалютах',
          summary: 'Крупные фонды продолжают наращивать инвестиции в цифровые активы. ${sentiment.topGainers.isNotEmpty ? "Особый интерес проявляется к ${sentiment.topGainers.first}." : ""}',
          expertName: 'Майкл Сэйлор',
          expertCredentials: 'CEO MicroStrategy',
          prediction: 'Ожидается рост на 15-20% в ближайшие 2 недели',
          timestamp: now.subtract(Duration(hours: _random.nextInt(6))),
          source: 'Bloomberg',
          isBullish: true,
        ),
        NewsArticleModel(
          id: 'bull_2',
          title: 'Технический анализ указывает на продолжение восходящего тренда',
          summary: 'Индикаторы RSI и MACD показывают сильные сигналы на покупку. Объемы торгов растут.',
          expertName: 'Кэти Вуд',
          expertCredentials: 'CEO ARK Invest',
          prediction: 'Целевой уровень Bitcoin: \$150,000 к концу года',
          timestamp: now.subtract(Duration(hours: _random.nextInt(12))),
          source: 'CoinDesk',
          isBullish: true,
        ),
        NewsArticleModel(
          id: 'bull_3',
          title: 'Binance сообщает о рекордных объемах торгов',
          summary: 'Крупнейшая биржа фиксирует приток новых пользователей и рост активности.',
          expertName: 'Чанпэн Чжао (CZ)',
          expertCredentials: 'Founder Binance',
          prediction: 'Альткоины могут вырасти на 30-50% вслед за Bitcoin',
          timestamp: now.subtract(Duration(hours: _random.nextInt(18))),
          source: 'Binance Blog',
          isBullish: true,
        ),
      ]);
    } else {
      news.addAll([
        NewsArticleModel(
          id: 'bull_1',
          title: 'Institutional Investors Increase Crypto Positions',
          summary: 'Major funds continue to expand their investments in digital assets. ${sentiment.topGainers.isNotEmpty ? "Particular interest is shown in ${sentiment.topGainers.first}." : ""}',
          expertName: 'Michael Saylor',
          expertCredentials: 'CEO MicroStrategy',
          prediction: 'Expected growth of 15-20% in the next 2 weeks',
          timestamp: now.subtract(Duration(hours: _random.nextInt(6))),
          source: 'Bloomberg',
          isBullish: true,
        ),
        NewsArticleModel(
          id: 'bull_2',
          title: 'Technical Analysis Points to Continued Uptrend',
          summary: 'RSI and MACD indicators show strong buy signals. Trading volumes are increasing.',
          expertName: 'Cathie Wood',
          expertCredentials: 'CEO ARK Invest',
          prediction: 'Bitcoin target: \$150,000 by year end',
          timestamp: now.subtract(Duration(hours: _random.nextInt(12))),
          source: 'CoinDesk',
          isBullish: true,
        ),
        NewsArticleModel(
          id: 'bull_3',
          title: 'Binance Reports Record Trading Volumes',
          summary: 'The largest exchange sees influx of new users and increased activity.',
          expertName: 'Changpeng Zhao (CZ)',
          expertCredentials: 'Founder Binance',
          prediction: 'Altcoins may surge 30-50% following Bitcoin',
          timestamp: now.subtract(Duration(hours: _random.nextInt(18))),
          source: 'Binance Blog',
          isBullish: true,
        ),
      ]);
    }

    return news;
  }

  List<NewsArticleModel> _generateBearishNews(String locale, MarketSentimentEntity sentiment) {
    final now = DateTime.now();
    final news = <NewsArticleModel>[];

    if (locale == 'ru') {
      news.addAll([
        NewsArticleModel(
          id: 'bear_1',
          title: 'Аналитики Glassnode предупреждают о возможной коррекции',
          summary: 'On-chain метрики показывают перегретость рынка. ${sentiment.topLosers.isNotEmpty ? "${sentiment.topLosers.first} показывает признаки слабости." : ""}',
          expertName: 'Уилли Ву',
          expertCredentials: 'On-Chain Analyst, Glassnode',
          prediction: 'Возможна коррекция на 10-15% перед продолжением роста',
          timestamp: now.subtract(Duration(hours: _random.nextInt(8))),
          source: 'Glassnode',
          isBullish: false,
        ),
        NewsArticleModel(
          id: 'bear_2',
          title: 'Фиксация прибыли крупными держателями',
          summary: 'Киты начинают продавать активы после значительного роста. Объемы продаж увеличиваются.',
          expertName: 'Питер Брандт',
          expertCredentials: 'Veteran Trader',
          prediction: 'Краткосрочное давление на цены, консолидация в течение 1-2 недель',
          timestamp: now.subtract(Duration(hours: _random.nextInt(10))),
          source: 'CryptoQuant',
          isBullish: false,
        ),
        NewsArticleModel(
          id: 'bear_3',
          title: 'ФРС США сохраняет жесткую монетарную политику',
          summary: 'Высокие процентные ставки создают давление на рисковые активы, включая криптовалюты.',
          expertName: 'Рауль Пал',
          expertCredentials: 'CEO Real Vision',
          prediction: 'Рекомендуется снижение рисков и диверсификация портфеля',
          timestamp: now.subtract(Duration(hours: _random.nextInt(14))),
          source: 'Reuters',
          isBullish: false,
        ),
      ]);
    } else {
      news.addAll([
        NewsArticleModel(
          id: 'bear_1',
          title: 'Glassnode Analysts Warn of Possible Correction',
          summary: 'On-chain metrics show market overheating. ${sentiment.topLosers.isNotEmpty ? "${sentiment.topLosers.first} shows signs of weakness." : ""}',
          expertName: 'Willy Woo',
          expertCredentials: 'On-Chain Analyst, Glassnode',
          prediction: 'Possible 10-15% correction before continued growth',
          timestamp: now.subtract(Duration(hours: _random.nextInt(8))),
          source: 'Glassnode',
          isBullish: false,
        ),
        NewsArticleModel(
          id: 'bear_2',
          title: 'Profit-Taking by Large Holders',
          summary: 'Whales are starting to sell assets after significant growth. Selling volumes are increasing.',
          expertName: 'Peter Brandt',
          expertCredentials: 'Veteran Trader',
          prediction: 'Short-term price pressure, consolidation for 1-2 weeks',
          timestamp: now.subtract(Duration(hours: _random.nextInt(10))),
          source: 'CryptoQuant',
          isBullish: false,
        ),
        NewsArticleModel(
          id: 'bear_3',
          title: 'US Fed Maintains Tight Monetary Policy',
          summary: 'High interest rates create pressure on risk assets, including cryptocurrencies.',
          expertName: 'Raoul Pal',
          expertCredentials: 'CEO Real Vision',
          prediction: 'Risk reduction and portfolio diversification recommended',
          timestamp: now.subtract(Duration(hours: _random.nextInt(14))),
          source: 'Reuters',
          isBullish: false,
        ),
      ]);
    }

    return news;
  }
}
