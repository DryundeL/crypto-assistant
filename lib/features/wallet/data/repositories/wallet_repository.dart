import 'dart:convert';
import 'package:crypto_assistant/features/wallet/data/models/transaction_model.dart';
import 'package:crypto_assistant/features/wallet/domain/entities/transaction_entity.dart';
import 'package:crypto_assistant/features/wallet/domain/repositories/i_wallet_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletRepository implements IWalletRepository {
  static const String _transactionsKey = 'wallet_transactions';
  final SharedPreferences _prefs;

  WalletRepository(this._prefs);

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    final jsonString = _prefs.getString(_transactionsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map<TransactionEntity>((json) => TransactionModel.fromJson(json)).toList();
  }

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    final transactions = await getTransactions();
    transactions.add(transaction);
    await _saveTransactions(transactions);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final transactions = await getTransactions();
    transactions.removeWhere((t) => t.id == id);
    await _saveTransactions(transactions);
  }

  Future<void> _saveTransactions(List<TransactionEntity> transactions) async {
    final models = transactions.map((t) => TransactionModel.fromEntity(t)).toList();
    final jsonString = jsonEncode(models.map((m) => m.toJson()).toList());
    await _prefs.setString(_transactionsKey, jsonString);
  }
}
