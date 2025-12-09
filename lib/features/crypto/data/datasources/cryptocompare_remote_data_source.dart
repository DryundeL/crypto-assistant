import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/recommendation_entity.dart';
import '../../domain/entities/crypto_coin_entity.dart';
import '../models/crypto_coin_model.dart';
import 'crypto_remote_data_source.dart';

class CryptoCompareRemoteDataSource implements ICryptoRemoteDataSource {
  static const String _baseUrl = 'https://min-api.cryptocompare.com/data';
  final http.Client client;

  CryptoCompareRemoteDataSource({required this.client});

  @override
  Future<List<CryptoCoinModel>> getTopCoins({String currencyCode = 'usd'}) async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/top/mktcapfull?limit=50&tsym=${currencyCode.toUpperCase()}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['Data'];
        
        return data.map((item) {
          final coinInfo = item['CoinInfo'];
          final raw = item['RAW']?[currencyCode.toUpperCase()];
          
          final id = (coinInfo['Name'] as String).toLowerCase();
          final symbol = (coinInfo['Name'] as String).toLowerCase();
          
          // Map some common IDs to match CoinGecko IDs if possible, or just use symbol
          // This is a limitation: IDs might not match across APIs.
          // Ideally we should map them, but for now we use what we get.
          
          return CryptoCoinModel(
            id: id, // CryptoCompare uses symbol as ID usually
            symbol: symbol,
            name: coinInfo['FullName'],
            currentPrice: raw != null ? (raw['PRICE'] as num).toDouble() : 0.0,
            priceChangePercentage24h: raw != null ? (raw['CHANGEPCT24HOUR'] as num).toDouble() : 0.0,
            image: 'https://www.cryptocompare.com${coinInfo['ImageUrl']}',
          );
        }).toList();
      } else {
        throw Exception('Failed to load coins: ${response.statusCode}');
      }
    } catch (e) {
      print('CryptoCompare Error: $e');
      throw Exception('CryptoCompare failed: $e');
    }
  }

  @override
  Future<CryptoCoinModel> getCoinDetails(String id) async {
    // CryptoCompare doesn't have a simple "details by ID" endpoint that matches CoinGecko's rich data
    // efficiently without multiple calls. 
    // We can use the pricemultifull endpoint if we treat ID as symbol.
    try {
      final symbol = id.toUpperCase(); // Assuming ID is symbol for CryptoCompare
      final response = await client.get(
        Uri.parse('$_baseUrl/pricemultifull?fsyms=$symbol&tsyms=USD'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final raw = jsonResponse['RAW']?[symbol]?['USD'];
        
        if (raw != null) {
           return CryptoCoinModel(
            id: id,
            symbol: id,
            name: id, // Name not available in this endpoint easily
            currentPrice: (raw['PRICE'] as num).toDouble(),
            priceChangePercentage24h: (raw['CHANGEPCT24HOUR'] as num).toDouble(),
            image: 'https://www.cryptocompare.com${raw['IMAGEURL']}',
            genesisDate: null,
          );
        }
      }
      throw Exception('Coin details not found');
    } catch (e) {
      throw Exception('CryptoCompare details failed: $e');
    }
  }

  @override
  Future<List<List<double>>> getMarketChart(String coinId, String period, double currentPrice, String currencyCode) async {
    try {
      String endpoint;
      int limit;
      
      switch (period) {
        case '1D': 
          endpoint = 'histominute'; 
          limit = 96; // 15 min intervals approx
          break;
        case '1W': 
          endpoint = 'histohour'; 
          limit = 168; 
          break;
        case '1M': 
          endpoint = 'histohour'; 
          limit = 720; // 6 hours? No, limit is count.
          // CryptoCompare limits might apply.
          limit = 120;
          break;
        case '1Y': 
          endpoint = 'histoday'; 
          limit = 365; 
          break;
        default: 
          endpoint = 'histohour';
          limit = 24;
      }

      final response = await client.get(
        Uri.parse('$_baseUrl/v2/$endpoint?fsym=${coinId.toUpperCase()}&tsym=${currencyCode.toUpperCase()}&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['Data']['Data'];
        
        return data.map<List<double>>((item) {
          return [
            (item['time'] as int).toDouble() * 1000, // Convert to ms
            (item['close'] as num).toDouble()
          ];
        }).toList();
      } else {
         throw Exception('Failed to load chart');
      }
    } catch (e) {
      throw Exception('CryptoCompare chart failed: $e');
    }
  }

  @override
  Future<RecommendationEntity> getAiRecommendation(List<CryptoCoinEntity> coins, String locale) async {
    // Mock implementation similar to others
    await Future.delayed(const Duration(seconds: 1));
    if (coins.isEmpty) throw Exception('No coins');
    
    final random = Random();
    final coin = coins[random.nextInt(coins.length)];
    
    return RecommendationEntity(
      coin: coin,
      reason: "AI Analysis (CryptoCompare): Market sentiment is positive for ${coin.name}.",
      confidenceScore: 0.82,
      whaleActivitySummary: "Moderate accumulation.",
      tradingVolume24h: "\$800M",
      change1W: 3.5,
      change1M: 8.0,
      change1Y: 15.0,
      prediction: "Steady Growth",
      analysisDetails: "RSI is neutral.",
    );
  }

  @override
  Future<double?> getCoinPriceAtDate(String coinId, String symbol, DateTime date, String currencyCode) async {
    try {
      final timestamp = (date.millisecondsSinceEpoch / 1000).round();
      final url = '$_baseUrl/pricehistorical?fsym=${symbol.toUpperCase()}&tsyms=${currencyCode.toUpperCase()}&ts=$timestamp';
      print('CryptoCompare Historical Request: $url');
      
      final response = await client.get(Uri.parse(url));
      
      print('CryptoCompare Historical Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // Response format: {"BTC":{"USD":432.1}}
        final price = jsonResponse[symbol.toUpperCase()]?[currencyCode.toUpperCase()];
        if (price != null) {
          return (price as num).toDouble();
        }
      }
      return null;
    } catch (e) {
      print('CryptoCompare historical price failed: $e');
      return null;
    }
  }
}
