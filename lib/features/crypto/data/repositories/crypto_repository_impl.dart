import 'dart:math';
import '../../domain/entities/crypto_coin_entity.dart';
import '../../domain/entities/recommendation_entity.dart';
import '../../domain/repositories/i_crypto_repository.dart';
import '../datasources/crypto_remote_data_source.dart';
import '../datasources/coin_detail_scraper.dart';
import '../models/crypto_coin_model.dart';

class CryptoRepositoryImpl implements ICryptoRepository {
  final List<ICryptoRemoteDataSource> dataSources;
  final CoinDetailScraper scraper;

  CryptoRepositoryImpl({
    required this.dataSources,
    required this.scraper,
  });

  @override
  Future<List<CryptoCoinEntity>> getTopCoins({String currencyCode = 'usd'}) async {
    for (final source in dataSources) {
      try {
        return await source.getTopCoins(currencyCode: currencyCode);
      } catch (e) {
        print('Source ${source.runtimeType} Failed (TopCoins): $e');
        // Continue to next source
      }
    }
    // If all failed, return mock (assuming the last one might be a MockDataSource, 
    // or we explicitly call a mock generator here).
    // Let's explicitly call the mock generator from the existing code if all fail.
    return _getMockCoins();
  }

  @override
  Future<CryptoCoinEntity> getCoinDetails(String id) async {
    CryptoCoinEntity? coin;
    
    for (final source in dataSources) {
      try {
        coin = await source.getCoinDetails(id);
        break; // Success
      } catch (e) {
        print('Source ${source.runtimeType} Failed (Details): $e');
      }
    }

    if (coin == null) {
      return _getMockCoinDetails(id);
    }

    // If we have a coin, try to enrich it with genesis date if missing
    if (coin.genesisDate == null) {
       // If we used secondary (CoinGecko), it might have genesis date already.
       // If not, or if we used primary (CoinCap), try scraper.
       try {
         final genesisDate = await scraper.getGenesisDate(id);
         if (genesisDate != null) {
           return CryptoCoinEntity(
             id: coin.id,
             symbol: coin.symbol,
             name: coin.name,
             currentPrice: coin.currentPrice,
             priceChangePercentage24h: coin.priceChangePercentage24h,
             image: coin.image,
             genesisDate: genesisDate,
           );
         }
       } catch (e) {
         print('Scraper Failed: $e');
       }
    }

    return coin;
  }

  @override
  Future<RecommendationEntity> getDailyRecommendation(List<CryptoCoinEntity> coins, String locale) async {
    for (final source in dataSources) {
      try {
        return await source.getAiRecommendation(coins, locale);
      } catch (e) {
        // Continue
      }
    }
    throw Exception('Failed to get recommendation');
  }

  @override
  Future<List<List<double>>> getMarketChart(String coinId, String period, double currentPrice, String currencyCode) async {
    for (final source in dataSources) {
      try {
        return await source.getMarketChart(coinId, period, currentPrice, currencyCode);
      } catch (e) {
        print('Source ${source.runtimeType} Failed (Chart): $e');
      }
    }
    return _generateMockChartData(period, currentPrice);
  }

  @override
  Future<double?> getCoinPriceAtDate(String coinId, String symbol, DateTime date, String currencyCode) async {
    for (final source in dataSources) {
      try {
        final price = await source.getCoinPriceAtDate(coinId, symbol, date, currencyCode);
        if (price != null) return price;
      } catch (e) {
        print('Source ${source.runtimeType} Failed (HistoricalPrice): $e');
      }
    }
    
    // Fallback to scraper
    try {
      print('Attempting to scrape historical price for $coinId on $date');
      // Resolve ID for scraper (needs slug)
      // We can use the coinId passed in, assuming it's the slug (which it usually is from the UI)
      // But if it's a symbol, we might need mapping. 
      // The UI passes coin.id which is usually the slug (e.g. 'bitcoin').
      final price = await scraper.getHistoricalPrice(coinId, date);
      if (price != null) return price;
    } catch (e) {
      print('Scraper Fallback Failed: $e');
    }

    return null;
  }

  // Mock Fallbacks (Duplicated from DataSources for Repository-level fallback)
  List<CryptoCoinModel> _getMockCoins() {
    final random = Random();
    double randomChange() => (random.nextDouble() * 20) - 10;
    
    return [
      CryptoCoinModel(id: 'bitcoin', symbol: 'btc', name: 'Bitcoin', currentPrice: 65000, priceChangePercentage24h: 2.5, image: 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png'),
      CryptoCoinModel(id: 'ethereum', symbol: 'eth', name: 'Ethereum', currentPrice: 3500, priceChangePercentage24h: 1.5, image: 'https://assets.coingecko.com/coins/images/279/large/ethereum.png'),
      CryptoCoinModel(id: 'solana', symbol: 'sol', name: 'Solana', currentPrice: 150, priceChangePercentage24h: 5.0, image: 'https://assets.coingecko.com/coins/images/4128/large/solana.png'),
      CryptoCoinModel(id: 'the-open-network', symbol: 'ton', name: 'Toncoin', currentPrice: 5.5, priceChangePercentage24h: 1.2, image: 'https://assets.coingecko.com/coins/images/17980/large/ton_symbol.png'),
    ];
  }

  CryptoCoinModel _getMockCoinDetails(String id) {
    return CryptoCoinModel(
      id: id, 
      symbol: 'unk', 
      name: 'Unknown', 
      currentPrice: 0, 
      priceChangePercentage24h: 0, 
      image: '',
      genesisDate: DateTime(2010, 1, 1),
    );
  }

  List<List<double>> _generateMockChartData(String period, double currentPrice) {
    final random = Random();
    final List<List<double>> chartData = [];
    final now = DateTime.now().millisecondsSinceEpoch;
    double price = currentPrice;
    
    for (int i = 0; i < 24; i++) {
      chartData.add([(now - i * 3600000).toDouble(), price]);
      price = price * (1 + (random.nextDouble() - 0.5) * 0.02);
    }
    return chartData.reversed.toList();
  }
}
