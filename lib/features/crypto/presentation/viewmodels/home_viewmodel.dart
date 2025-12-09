import 'package:flutter/material.dart';
import '../../domain/entities/crypto_coin_entity.dart';
import '../../domain/entities/recommendation_entity.dart';
import '../../domain/repositories/i_crypto_repository.dart';

enum HomeState { initial, loading, loaded, error }

class HomeViewModel extends ChangeNotifier {
  final ICryptoRepository repository;

  HomeViewModel({required this.repository});

  HomeState _state = HomeState.initial;
  HomeState get state => _state;

  List<CryptoCoinEntity> _coins = [];
  List<CryptoCoinEntity> get coins => _searchQuery.isEmpty 
      ? _coins 
      : _coins.where((coin) => 
          coin.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
          coin.symbol.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  RecommendationEntity? _recommendation;
  RecommendationEntity? get recommendation => _recommendation;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isRecommendationLoading = false;
  bool get isRecommendationLoading => _isRecommendationLoading;

  String _currency = 'usd';
  String get currency => _currency;

  void updateCurrency(String newCurrency) {
    if (_currency != newCurrency) {
      _currency = newCurrency;
      loadCoins();
    }
  }

  Future<void> loadCoins() async {
    _state = HomeState.loading;
    notifyListeners();

    try {
      _coins = await repository.getTopCoins(currencyCode: _currency);
      _state = HomeState.loaded;
    } catch (e) {
      _state = HomeState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> getRecommendation(String locale) async {
    if (_coins.isEmpty) return;

    _isRecommendationLoading = true;
    notifyListeners();

    try {
      _recommendation = await repository.getDailyRecommendation(_coins, locale);
    } catch (e) {
      _errorMessage = "Failed to get recommendation: $e";
    } finally {
      _isRecommendationLoading = false;
      notifyListeners();
    }

  }

  void searchCoins(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
