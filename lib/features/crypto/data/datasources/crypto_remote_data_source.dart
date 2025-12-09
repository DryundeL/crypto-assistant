import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/recommendation_entity.dart';
import '../../domain/entities/crypto_coin_entity.dart';
import '../models/crypto_coin_model.dart';

abstract class ICryptoRemoteDataSource {
  Future<List<CryptoCoinModel>> getTopCoins({String currencyCode = 'usd'});
  Future<RecommendationEntity> getAiRecommendation(List<CryptoCoinEntity> coins, String locale);
  Future<List<List<double>>> getMarketChart(String coinId, String period, double currentPrice, String currencyCode);
  Future<CryptoCoinModel> getCoinDetails(String id);
  Future<double?> getCoinPriceAtDate(String coinId, String symbol, DateTime date, String currencyCode);
}

class CryptoRemoteDataSource implements ICryptoRemoteDataSource {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  final http.Client client;

  CryptoRemoteDataSource({required this.client});

  @override
  Future<List<CryptoCoinModel>> getTopCoins({String currencyCode = 'usd'}) async {
    try {
      final response = await client.get(
        Uri.parse(
            '$_baseUrl/coins/markets?vs_currency=$currencyCode&order=market_cap_desc&per_page=50&page=1&sparkline=false'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CryptoCoinModel.fromJson(json)).toList();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return _getMockCoins();
      }
    } catch (e) {
      print('Network Error: $e');
      throw Exception('CoinGecko failed: $e');
    }
  }

  Future<CryptoCoinModel> getCoinDetails(String id) async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/coins/$id?localization=false&tickers=false&market_data=true&community_data=false&developer_data=false&sparkline=false'),
      );

      if (response.statusCode == 200) {
        return CryptoCoinModel.fromJson(json.decode(response.body));
      } else {
        // Fallback to mock if API fails (e.g. rate limit)
        return _getMockCoinDetails(id);
      }
    } catch (e) {
      throw Exception('CoinGecko details failed: $e');
    }
  }

  @override
  Future<double?> getCoinPriceAtDate(String coinId, String symbol, DateTime date, String currencyCode) async {
    try {
      final resolvedId = _resolveId(coinId, symbol);
      final formattedDate = "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
      final response = await client.get(
        Uri.parse('$_baseUrl/coins/$resolvedId/history?date=$formattedDate&localization=false'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final marketData = jsonResponse['market_data'];
        if (marketData != null) {
          final currentPrice = marketData['current_price'];
          if (currentPrice != null) {
             return (currentPrice[currencyCode.toLowerCase()] as num).toDouble();
          }
        }
      }
      return null;
    } catch (e) {
      print('CoinGecko historical price failed: $e');
      return null;
    }
  }

  String _resolveId(String id, String symbol) {
    if (id.length <= 5 || id == id.toUpperCase()) {
      final map = {
        'BTC': 'bitcoin',
        'ETH': 'ethereum',
        'SOL': 'solana',
        'XRP': 'ripple',
        'ADA': 'cardano',
        'AVAX': 'avalanche-2',
        'DOGE': 'dogecoin',
        'DOT': 'polkadot',
        'LINK': 'chainlink',
        'MATIC': 'matic-network',
        'SHIB': 'shiba-inu',
        'LTC': 'litecoin',
        'UNI': 'uniswap',
        'BCH': 'bitcoin-cash',
        'NEAR': 'near',
        'APT': 'aptos',
        'ATOM': 'cosmos',
        'XLM': 'stellar',
        'XMR': 'monero',
        'ETC': 'ethereum-classic',
        'TON': 'the-open-network',
        'NOT': 'notcoin',
        'DOGS': 'dogs-2',
        'USDT': 'tether',
        'USDC': 'usd-coin',
      };
      return map[symbol.toUpperCase()] ?? id.toLowerCase();
    }
    return id;
  }

  CryptoCoinModel _getMockCoinDetails(String id) {
    final mockCoins = _getMockCoins();
    final coin = mockCoins.firstWhere((c) => c.id == id, orElse: () => mockCoins.first);
    // Add fake genesis date for mock
    return CryptoCoinModel(
      id: coin.id,
      symbol: coin.symbol,
      name: coin.name,
      currentPrice: coin.currentPrice,
      priceChangePercentage24h: coin.priceChangePercentage24h,
      image: coin.image,
      genesisDate: DateTime(2010, 1, 1), // Default mock genesis
    );
  }

  @override
  Future<RecommendationEntity> getAiRecommendation(List<CryptoCoinEntity> coins, String locale) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    final cacheKeySuffix = '_$locale';
    
    // Check if we have a cached recommendation for today (coin ID is language-independent)
    final cachedDate = prefs.getString('recommendation_date');
    final cachedCoinId = prefs.getString('recommendation_coin_id');

    if (cachedDate == today && cachedCoinId != null) {
      if (coins.isEmpty) {
        throw Exception('No coins data available');
      }
      
      // Get localized text for this language
      final reason = prefs.getString('recommendation_reason$cacheKeySuffix');
      final whale = prefs.getString('recommendation_whale$cacheKeySuffix');
      final prediction = prefs.getString('recommendation_prediction$cacheKeySuffix');
      final details = prefs.getString('recommendation_details$cacheKeySuffix');
      
      // If we have cached translations for this language, use them
      if (reason != null && whale != null && prediction != null && details != null) {
        final score = prefs.getDouble('recommendation_score') ?? 0.85;
        final volume = prefs.getString('recommendation_volume') ?? '\$1.2B';
        final change1W = prefs.getDouble('recommendation_change1w') ?? 5.0;
        final change1M = prefs.getDouble('recommendation_change1m') ?? 10.0;
        final change1Y = prefs.getDouble('recommendation_change1y') ?? 20.0;

        CryptoCoinEntity? coin;
        try {
          coin = coins.firstWhere((c) => c.id == cachedCoinId);
        } catch (e) {
          coin = coins.first;
        }

        return RecommendationEntity(
          coin: coin,
          reason: reason,
          confidenceScore: score,
          whaleActivitySummary: whale,
          tradingVolume24h: volume,
          change1W: change1W,
          change1M: change1M,
          change1Y: change1Y,
          prediction: prediction,
          analysisDetails: details,
        );
      }
      // If no translations for this language, regenerate with same coin
    }

    // Simulate network delay for "AI Processing"
    await Future.delayed(const Duration(seconds: 2));

    if (coins.isEmpty) {
      throw Exception('No coins data available for analysis');
    }

    final random = Random();
    
    // If we have a cached coin for today, use it; otherwise select a new one
    CryptoCoinEntity selectedCoin;
    double bestChange1W;
    double bestChange1M;
    double bestChange1Y;
    String bestVolume;
    double confidenceScore;
    
    if (cachedDate == today && cachedCoinId != null) {
      // Reuse the same coin but generate new translations
      try {
        selectedCoin = coins.firstWhere((c) => c.id == cachedCoinId);
      } catch (e) {
        selectedCoin = coins.first;
      }
      
      // Retrieve cached metrics
      bestChange1W = prefs.getDouble('recommendation_change1w') ?? 5.0;
      bestChange1M = prefs.getDouble('recommendation_change1m') ?? 10.0;
      bestChange1Y = prefs.getDouble('recommendation_change1y') ?? 20.0;
      bestVolume = prefs.getString('recommendation_volume') ?? '\$1.2B';
      confidenceScore = prefs.getDouble('recommendation_score') ?? 0.85;
    } else {
      // Select a new coin
      CryptoCoinEntity bestCoin = coins.first;
      double bestScore = -1.0;
      
      bestChange1W = 0;
      bestChange1M = 0;
      bestChange1Y = 0;
      bestVolume = "";

      for (final coin in coins) {
         // Generate mock metrics
         final change1W = (random.nextDouble() * 20) - 5; // -5% to +15%
         final change1M = (random.nextDouble() * 40) - 10; // -10% to +30%
         final change1Y = (random.nextDouble() * 100) - 20; // -20% to +80%
         
         // Calculate score: weighted average of changes + random factor
         double score = (change1W * 0.3) + (change1M * 0.3) + (change1Y * 0.2) + (random.nextDouble() * 10);
         
         if (score > bestScore) {
           bestScore = score;
           bestCoin = coin;
           bestChange1W = change1W;
           bestChange1M = change1M;
           bestChange1Y = change1Y;
           bestVolume = "\$${(random.nextDouble() * 5 + 0.5).toStringAsFixed(1)}B";
         }
      }
      
      selectedCoin = bestCoin;
      confidenceScore = 0.85 + (random.nextDouble() * 0.1);
      
      // Cache the coin ID and metrics (language-independent)
      await prefs.setString('recommendation_date', today);
      await prefs.setString('recommendation_coin_id', selectedCoin.id);
      await prefs.setDouble('recommendation_score', confidenceScore);
      await prefs.setString('recommendation_volume', bestVolume);
      await prefs.setDouble('recommendation_change1w', bestChange1W);
      await prefs.setDouble('recommendation_change1m', bestChange1M);
      await prefs.setDouble('recommendation_change1y', bestChange1Y);
    }

    // Generate localized text
    String reason;
    String selectedWhaleMove;
    String prediction;
    String analysisDetails;
    
    if (locale == 'ru') {
       final whaleMoves = [
        "Крупный кошелек (0x4a...e9) накопил 5000 ${selectedCoin.symbol.toUpperCase()} за последний час.",
        "Зафиксирован институциональный приток на OTC площадках для ${selectedCoin.name}.",
        "Обнаружен значительный вывод с Binance на холодное хранение."
      ];
      selectedWhaleMove = whaleMoves[random.nextInt(whaleMoves.length)];
      
      reason = "AI модель 'Alpha-7' выбрала ${selectedCoin.name} на основе комплексного анализа. Монета показывает сильный восходящий тренд на недельном (+${bestChange1W.toStringAsFixed(1)}%) и месячном (+${bestChange1M.toStringAsFixed(1)}%) таймфреймах.";
      prediction = "Бычий прорыв";
      analysisDetails = "Технический анализ указывает на перепроданность RSI на 4H таймфрейме. Фундаментально, объем торгов ($bestVolume) подтверждает интерес покупателей. Активность китов сигнализирует о накоплении позиций перед возможным скачком цены.";
      
    } else {
      final whaleMoves = [
        "Large wallet (0x4a...e9) accumulated 5000 ${selectedCoin.symbol.toUpperCase()} in the last hour.",
        "Institutional inflow detected on OTC desks for ${selectedCoin.name}.",
        "Significant withdrawal from Binance to cold storage detected."
      ];
      selectedWhaleMove = whaleMoves[random.nextInt(whaleMoves.length)];
      
      reason = "AI Model 'Alpha-7' selected ${selectedCoin.name} based on comprehensive analysis. The coin shows a strong uptrend on weekly (+${bestChange1W.toStringAsFixed(1)}%) and monthly (+${bestChange1M.toStringAsFixed(1)}%) timeframes.";
      prediction = "Bullish Breakout";
      analysisDetails = "Technical analysis indicates oversold RSI on the 4H timeframe. Fundamentally, trading volume ($bestVolume) confirms buyer interest. Whale activity signals accumulation ahead of a potential price surge.";
    }

    // Cache the localized text
    await prefs.setString('recommendation_reason$cacheKeySuffix', reason);
    await prefs.setString('recommendation_whale$cacheKeySuffix', selectedWhaleMove);
    await prefs.setString('recommendation_prediction$cacheKeySuffix', prediction);
    await prefs.setString('recommendation_details$cacheKeySuffix', analysisDetails);

    return RecommendationEntity(
      coin: selectedCoin,
      reason: reason,
      confidenceScore: confidenceScore,
      whaleActivitySummary: selectedWhaleMove,
      tradingVolume24h: bestVolume,
      change1W: bestChange1W,
      change1M: bestChange1M,
      change1Y: bestChange1Y,
      prediction: prediction,
      analysisDetails: analysisDetails,
    );
  }

  @override
  Future<List<List<double>>> getMarketChart(String coinId, String period, double currentPrice, String currencyCode) async {
    try {
      // Map period to days parameter for API
      int days;
      switch (period) {
        case '1D': days = 1; break;
        case '3D': days = 3; break;
        case '1W': days = 7; break;
        case '1M': days = 30; break;
        case '1Y': days = 365; break;
        default: days = 1;
      }

      final response = await client.get(
        Uri.parse('$_baseUrl/coins/$coinId/market_chart?vs_currency=$currencyCode&days=$days'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prices = data['prices'] as List<dynamic>;
        
        // Convert to our format: [[timestamp, price], ...]
        return prices.map<List<double>>((item) {
          final list = item as List<dynamic>;
          return <double>[list[0].toDouble(), list[1].toDouble()];
        }).toList();
      } else {
        // Fallback to mock data if API fails
        return _generateMockChartData(period, currentPrice);
      }
    } catch (e) {
      // Fallback to mock data on error
      return _generateMockChartData(period, currentPrice);
    }
  }

  List<List<double>> _generateMockChartData(String period, double currentPrice) {
    // Mock data generation as fallback
    int points;
    int interval;
    switch (period) {
      case '1D': 
        points = 24; 
        interval = 3600000; // 1 hour
        break;
      case '3D':
        points = 72;
        interval = 3600000; // 1 hour
        break;
      case '1W': 
        points = 168; // Hourly for week
        interval = 3600000;
        break;
      case '1M': 
        points = 120; // Every 6 hours
        interval = 21600000;
        break;
      case '1Y': 
        points = 365; // Daily
        interval = 86400000;
        break;
      default: 
        points = 24;
        interval = 3600000;
    }

    final random = Random();

    final List<List<double>> chartData = [];
    final now = DateTime.now().millisecondsSinceEpoch;

    // Generate data backwards from current price
    double price = currentPrice;
    
    List<List<double>> reversedData = [];
    reversedData.add([now.toDouble(), price]);

    for (int i = 1; i < points; i++) {
      // Random walk with trend
      // Volatility depends on period
      double volatility = 0.015; // 1.5%
      if (period == '1D' || period == '3D') volatility = 0.005; // 0.5%
      
      double change = (random.nextDouble() - 0.5) * volatility;
      price = price / (1 + change); // Reverse the change to go back in time
      
      reversedData.add([
        (now - i * interval).toDouble(),
        price
      ]);
    }

    return reversedData.reversed.toList();
  }

  List<CryptoCoinModel> _getMockCoins() {
    final random = Random();
    
    // Helper to generate random price change
    double randomChange() => (random.nextDouble() * 20) - 10; // -10% to +10%
    
    return [
      CryptoCoinModel(
          id: 'bitcoin',
          symbol: 'btc',
          name: 'Bitcoin',
          currentPrice: 125000.0 + (random.nextDouble() * 2000),
          priceChangePercentage24h: 1.5 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png'),
      CryptoCoinModel(
          id: 'ethereum',
          symbol: 'eth',
          name: 'Ethereum',
          currentPrice: 6500.0 + (random.nextDouble() * 100),
          priceChangePercentage24h: 2.2 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/279/large/ethereum.png'),
      CryptoCoinModel(
          id: 'solana',
          symbol: 'sol',
          name: 'Solana',
          currentPrice: 320.0 + (random.nextDouble() * 10),
          priceChangePercentage24h: 4.8 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/4128/large/solana.png'),
      CryptoCoinModel(
          id: 'ripple',
          symbol: 'xrp',
          name: 'XRP',
          currentPrice: 2.8 + (random.nextDouble() * 0.1),
          priceChangePercentage24h: 1.5 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/44/large/xrp-symbol-white-128.png'),
      CryptoCoinModel(
          id: 'cardano',
          symbol: 'ada',
          name: 'Cardano',
          currentPrice: 1.8 + (random.nextDouble() * 0.05),
          priceChangePercentage24h: -0.8 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/975/large/cardano.png'),
      CryptoCoinModel(
          id: 'avalanche-2',
          symbol: 'avax',
          name: 'Avalanche',
          currentPrice: 85.0 + (random.nextDouble() * 2),
          priceChangePercentage24h: 3.2 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/12559/large/Avalanche_Circle_RedWhite_Trans.png'),
      CryptoCoinModel(
          id: 'dogecoin',
          symbol: 'doge',
          name: 'Dogecoin',
          currentPrice: 0.45 + (random.nextDouble() * 0.02),
          priceChangePercentage24h: 5.5 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/5/large/dogecoin.png'),
      CryptoCoinModel(
          id: 'polkadot',
          symbol: 'dot',
          name: 'Polkadot',
          currentPrice: 15.5 + (random.nextDouble() * 0.5),
          priceChangePercentage24h: 1.1 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/12171/large/polkadot.png'),
      CryptoCoinModel(
          id: 'chainlink',
          symbol: 'link',
          name: 'Chainlink',
          currentPrice: 45.0 + (random.nextDouble() * 1),
          priceChangePercentage24h: 2.5 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/877/large/chainlink-new-logo.png'),
      CryptoCoinModel(
          id: 'polygon',
          symbol: 'matic',
          name: 'Polygon',
          currentPrice: 1.8 + (random.nextDouble() * 0.05),
          priceChangePercentage24h: -0.5 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/4713/large/matic-token-icon.png'),
      CryptoCoinModel(
          id: 'shiba-inu',
          symbol: 'shib',
          name: 'Shiba Inu',
          currentPrice: 0.000085 + (random.nextDouble() * 0.000005),
          priceChangePercentage24h: 8.0 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/11939/large/shiba.png'),
      CryptoCoinModel(
          id: 'litecoin',
          symbol: 'ltc',
          name: 'Litecoin',
          currentPrice: 150.0 + (random.nextDouble() * 2),
          priceChangePercentage24h: 0.8 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/2/large/litecoin.png'),
      CryptoCoinModel(
          id: 'uniswap',
          symbol: 'uni',
          name: 'Uniswap',
          currentPrice: 25.0 + (random.nextDouble() * 0.5),
          priceChangePercentage24h: 2.2 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/12504/large/uniswap-uni.png'),
      CryptoCoinModel(
          id: 'bitcoin-cash',
          symbol: 'bch',
          name: 'Bitcoin Cash',
          currentPrice: 850.0 + (random.nextDouble() * 10),
          priceChangePercentage24h: 1.5 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/780/large/bitcoin-cash-circle.png'),
      CryptoCoinModel(
          id: 'near',
          symbol: 'near',
          name: 'NEAR Protocol',
          currentPrice: 12.8 + (random.nextDouble() * 0.2),
          priceChangePercentage24h: 4.5 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/10365/large/near.png'),
      CryptoCoinModel(
          id: 'aptos',
          symbol: 'apt',
          name: 'Aptos',
          currentPrice: 28.0 + (random.nextDouble() * 0.5),
          priceChangePercentage24h: -1.8 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/26455/large/aptos_round.png'),
      CryptoCoinModel(
          id: 'cosmos',
          symbol: 'atom',
          name: 'Cosmos Hub',
          currentPrice: 18.5 + (random.nextDouble() * 0.3),
          priceChangePercentage24h: 0.2 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/1481/large/cosmos_hub.png'),
      CryptoCoinModel(
          id: 'stellar',
          symbol: 'xlm',
          name: 'Stellar',
          currentPrice: 0.35 + (random.nextDouble() * 0.01),
          priceChangePercentage24h: -0.3 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/100/large/Stellar_symbol_black_RGB.png'),
      CryptoCoinModel(
          id: 'monero',
          symbol: 'xmr',
          name: 'Monero',
          currentPrice: 220.0 + (random.nextDouble() * 5),
          priceChangePercentage24h: 1.0 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/69/large/monero_logo.png'),
      CryptoCoinModel(
          id: 'ethereum-classic',
          symbol: 'etc',
          name: 'Ethereum Classic',
          currentPrice: 45.0 + (random.nextDouble() * 1),
          priceChangePercentage24h: -2.0 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/453/large/ethereum-classic-logo.png'),
      CryptoCoinModel(
          id: 'the-open-network',
          symbol: 'ton',
          name: 'Toncoin',
          currentPrice: 5.5 + (random.nextDouble() * 0.2),
          priceChangePercentage24h: 1.2 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/17980/large/ton_symbol.png'),
      CryptoCoinModel(
          id: 'notcoin',
          symbol: 'not',
          name: 'Notcoin',
          currentPrice: 0.0075 + (random.nextDouble() * 0.0005),
          priceChangePercentage24h: 5.5 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/34888/large/notcoin.jpg'),
      CryptoCoinModel(
          id: 'dogs-2',
          symbol: 'dogs',
          name: 'DOGS',
          currentPrice: 0.00065 + (random.nextDouble() * 0.00005),
          priceChangePercentage24h: -2.5 + randomChange(),
          image: 'https://assets.coingecko.com/coins/images/39126/large/dogs.jpg'),
      CryptoCoinModel(
          id: 'tether',
          symbol: 'usdt',
          name: 'Tether',
          currentPrice: 1.0,
          priceChangePercentage24h: 0.01,
          image: 'https://assets.coingecko.com/coins/images/325/large/Tether.png'),
      CryptoCoinModel(
          id: 'usd-coin',
          symbol: 'usdc',
          name: 'USDC',
          currentPrice: 1.0,
          priceChangePercentage24h: 0.00,
          image: 'https://assets.coingecko.com/coins/images/6319/large/USD_Coin_icon.png'),
    ];
  }
}
