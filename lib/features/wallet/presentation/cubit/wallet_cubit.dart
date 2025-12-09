import 'package:bloc/bloc.dart';
import 'package:crypto_assistant/features/crypto/domain/repositories/i_crypto_repository.dart';
import 'package:crypto_assistant/features/wallet/domain/entities/transaction_entity.dart';
import 'package:crypto_assistant/features/wallet/domain/repositories/i_wallet_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:crypto_assistant/features/crypto/domain/entities/crypto_coin_entity.dart';

enum WalletStatus { initial, loading, success, failure }

class WalletState extends Equatable {
  final WalletStatus status;
  final List<TransactionEntity> transactions;
  final double portfolioValue;
  final double totalProfitLoss;
  final Map<String, double> coinHoldings; // CoinId -> Amount
  final Map<String, double> coinValues; // CoinId -> Current Value
  final Map<String, double> coinProfits; // CoinId -> Profit/Loss
  final Map<String, double> coinProfitPercentages; // CoinId -> Profit/Loss %
  final Map<String, String> coinImages; // CoinId -> ImageUrl
  final double totalProfitLossPercentage;
  final String? errorMessage;

  const WalletState({
    this.status = WalletStatus.initial,
    this.transactions = const [],
    this.portfolioValue = 0.0,
    this.totalProfitLoss = 0.0,
    this.coinHoldings = const {},
    this.coinValues = const {},
    this.coinProfits = const {},
    this.coinProfitPercentages = const {},
    this.coinImages = const {},
    this.totalProfitLossPercentage = 0.0,
    this.errorMessage,
  });

  WalletState copyWith({
    WalletStatus? status,
    List<TransactionEntity>? transactions,
    double? portfolioValue,
    double? totalProfitLoss,
    Map<String, double>? coinHoldings,
    Map<String, double>? coinValues,
    Map<String, double>? coinProfits,
    Map<String, double>? coinProfitPercentages,
    Map<String, String>? coinImages,
    double? totalProfitLossPercentage,
    String? errorMessage,
  }) {
    return WalletState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      portfolioValue: portfolioValue ?? this.portfolioValue,
      totalProfitLoss: totalProfitLoss ?? this.totalProfitLoss,
      coinHoldings: coinHoldings ?? this.coinHoldings,
      coinValues: coinValues ?? this.coinValues,
      coinProfits: coinProfits ?? this.coinProfits,
      coinProfitPercentages: coinProfitPercentages ?? this.coinProfitPercentages,
      coinImages: coinImages ?? this.coinImages,
      totalProfitLossPercentage: totalProfitLossPercentage ?? this.totalProfitLossPercentage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, transactions, portfolioValue, totalProfitLoss, coinHoldings, coinValues, coinProfits, coinProfitPercentages, coinImages, totalProfitLossPercentage, errorMessage];
}

class WalletCubit extends Cubit<WalletState> {
  final IWalletRepository _walletRepository;
  final ICryptoRepository _cryptoRepository;

  WalletCubit({
    required IWalletRepository walletRepository,
    required ICryptoRepository cryptoRepository,
  })  : _walletRepository = walletRepository,
        _cryptoRepository = cryptoRepository,
        super(const WalletState());

  String _currency = 'usd';

  void updateCurrency(String currency) {
    if (_currency != currency) {
      _currency = currency;
      loadWallet();
    }
  }

  Future<void> loadWallet() async {
    emit(state.copyWith(status: WalletStatus.loading));
    try {
      final transactions = await _walletRepository.getTransactions();
      await _calculatePortfolio(transactions);
    } catch (e) {
      emit(state.copyWith(status: WalletStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> addTransaction(TransactionEntity transaction) async {
    try {
      await _walletRepository.addTransaction(transaction);
      await loadWallet();
    } catch (e) {
      emit(state.copyWith(status: WalletStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      // Optimistic update to remove transaction immediately from UI
      // This prevents "Dismissible widget is still part of the tree" error
      final updatedTransactions = state.transactions.where((t) => t.id != id).toList();
      emit(state.copyWith(transactions: updatedTransactions));

      await _walletRepository.deleteTransaction(id);
      await loadWallet();
    } catch (e) {
      emit(state.copyWith(status: WalletStatus.failure, errorMessage: e.toString()));
      loadWallet(); // Reload to restore correct state on failure
    }
  }

  Future<void> _calculatePortfolio(List<TransactionEntity> transactions) async {
    if (transactions.isEmpty) {
      emit(state.copyWith(
        status: WalletStatus.success,
        transactions: [],
        portfolioValue: 0.0,
        totalProfitLoss: 0.0,
        coinHoldings: {},
        coinValues: {},
        coinProfits: {},
        coinProfitPercentages: {},
        coinImages: {},
        totalProfitLossPercentage: 0.0,
      ));
      return;
    }

    // Fetch current prices
    // Note: In a real app, we should fetch prices for specific coins.
    // Here we fetch top coins and hope our coins are in there.
    // If not, we might need a better API or fallback.
    List<CryptoCoinEntity> coins = [];
    try {
      coins = await _cryptoRepository.getTopCoins(currencyCode: _currency);
    } catch (e) {
      print('WalletCubit: Failed to fetch prices: $e');
      // Continue with empty coins list, using buy price as fallback
    }
    
    final priceMap = {for (var c in coins) c.symbol.toLowerCase(): c.currentPrice};
    final imageMap = {for (var c in coins) c.symbol.toLowerCase(): c.image};

    final change24hMap = {for (var c in coins) c.symbol.toLowerCase(): c.priceChangePercentage24h};

    double totalValue = 0.0;
    double totalCost = 0.0;
    
    // For 24h PnL calculation
    double totalValue24hAgo = 0.0;
    
    final Map<String, double> holdings = {};
    final Map<String, double> values = {};
    final Map<String, double> profits = {}; // This will now store 24h PnL per coin (aggregated)
    final Map<String, double> profitPercentages = {}; // This will store 24h change %
    final Map<String, double> costs = {};

    for (var t in transactions) {
      final symbolKey = t.coinSymbol.toLowerCase();
      final currentPrice = priceMap[symbolKey] ?? t.pricePerCoin;
      final change24h = change24hMap[symbolKey] ?? 0.0;
      
      final value = t.amount * currentPrice;
      final cost = t.amount * t.pricePerCoin;

      // Calculate value 24h ago: current / (1 + change/100)
      final price24hAgo = currentPrice / (1 + (change24h / 100));
      final value24hAgo = t.amount * price24hAgo;

      totalValue += value;
      totalCost += cost;
      totalValue24hAgo += value24hAgo;

      holdings[t.coinId] = (holdings[t.coinId] ?? 0.0) + t.amount;
      values[t.coinId] = (values[t.coinId] ?? 0.0) + value;
      costs[t.coinId] = (costs[t.coinId] ?? 0.0) + cost;
    }

    // Calculate 24h PnL for the whole portfolio
    final total24hPnL = totalValue - totalValue24hAgo;
    
    double totalPnLPercentage = 0.0;
    if (totalValue24hAgo > 0) {
      totalPnLPercentage = (total24hPnL / totalValue24hAgo) * 100;
    }

    for (var coinId in holdings.keys) {
      // For individual coins in the list, we show their 24h change %
      // We need to find the coin entity to get the exact 24h change
      // But we aggregated by coinId.
      // Let's assume all transactions for the same coin have the same 24h change (which is true).
      
      // We need to find the symbol for this coinId to look up the change
      // We can find it from the first transaction for this coinId
      final transaction = transactions.firstWhere((t) => t.coinId == coinId);
      final symbolKey = transaction.coinSymbol.toLowerCase();
      final change24h = change24hMap[symbolKey] ?? 0.0;
      
      // Profit for the coin entry in the list will be its 24h PnL
      final currentValue = values[coinId] ?? 0.0;
      final price24hAgo = currentValue / (1 + (change24h / 100));
      profits[coinId] = currentValue - price24hAgo;
      
      profitPercentages[coinId] = change24h;
    }

    emit(state.copyWith(
      status: WalletStatus.success,
      transactions: transactions,
      portfolioValue: totalValue,
      totalProfitLoss: total24hPnL, // Now 24h PnL
      coinHoldings: holdings,
      coinValues: values,
      coinProfits: profits, // Now 24h PnL per coin
      coinProfitPercentages: profitPercentages, // Now 24h change %
      coinImages: imageMap,
      totalProfitLossPercentage: totalPnLPercentage, // Now 24h change %
    ));
  }
}
