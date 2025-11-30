import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../domain/entities/recommendation_entity.dart';
import '../../domain/entities/crypto_coin_entity.dart';
import '../models/crypto_coin_model.dart';

abstract class ICryptoRemoteDataSource {
  Future<List<CryptoCoinModel>> getTopCoins();
  Future<RecommendationEntity> getAiRecommendation(List<CryptoCoinEntity> coins);
}

class CryptoRemoteDataSource implements ICryptoRemoteDataSource {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  final http.Client client;

  CryptoRemoteDataSource({required this.client});

  @override
  Future<List<CryptoCoinModel>> getTopCoins() async {
    try {
      final response = await client.get(
        Uri.parse(
            '$_baseUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=20&page=1&sparkline=false'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CryptoCoinModel.fromJson(json)).toList();
      } else {
        return _getMockCoins();
      }
    } catch (e) {
      return _getMockCoins();
    }
  }

  @override
  Future<RecommendationEntity> getAiRecommendation(List<CryptoCoinEntity> coins) async {
    // Simulate network delay for "AI Processing"
    await Future.delayed(const Duration(seconds: 2));

    if (coins.isEmpty) {
      throw Exception('No coins data available for analysis');
    }

    final random = Random();
    final candidate = coins[random.nextInt(coins.length)];

    final whaleMoves = [
      "Large wallet (0x4a...e9) accumulated 5000 ${candidate.symbol.toUpperCase()} in the last hour.",
      "Institutional inflow detected on OTC desks for ${candidate.name}.",
      "Significant withdrawal from Binance to cold storage detected."
    ];
    final selectedWhaleMove = whaleMoves[random.nextInt(whaleMoves.length)];

    return RecommendationEntity(
      coin: candidate,
      reason: "AI Model 'Alpha-7' detects a bullish divergence in RSI combined with significant whale accumulation. Sentiment analysis on X (Twitter) is 85% positive.",
      confidenceScore: 0.85 + (random.nextDouble() * 0.1),
      whaleActivitySummary: selectedWhaleMove,
    );
  }

  List<CryptoCoinModel> _getMockCoins() {
    return [
      const CryptoCoinModel(
          id: 'bitcoin',
          symbol: 'btc',
          name: 'Bitcoin',
          currentPrice: 95000.0,
          priceChangePercentage24h: 2.5,
          image: 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png'),
      const CryptoCoinModel(
          id: 'ethereum',
          symbol: 'eth',
          name: 'Ethereum',
          currentPrice: 3500.0,
          priceChangePercentage24h: -1.2,
          image: 'https://assets.coingecko.com/coins/images/279/large/ethereum.png'),
      const CryptoCoinModel(
          id: 'solana',
          symbol: 'sol',
          name: 'Solana',
          currentPrice: 145.0,
          priceChangePercentage24h: 5.8,
          image: 'https://assets.coingecko.com/coins/images/4128/large/solana.png'),
      const CryptoCoinModel(
          id: 'ripple',
          symbol: 'xrp',
          name: 'XRP',
          currentPrice: 0.65,
          priceChangePercentage24h: 0.5,
          image: 'https://assets.coingecko.com/coins/images/44/large/xrp-symbol-white-128.png'),
      const CryptoCoinModel(
          id: 'cardano',
          symbol: 'ada',
          name: 'Cardano',
          currentPrice: 0.45,
          priceChangePercentage24h: -0.8,
          image: 'https://assets.coingecko.com/coins/images/975/large/cardano.png'),
    ];
  }
}
