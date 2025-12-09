import 'dart:convert';
import 'package:crypto_assistant/features/wallet/domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.coinId,
    required super.coinSymbol,
    required super.amount,
    required super.date,
    required super.pricePerCoin,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      coinId: json['coinId'],
      coinSymbol: json['coinSymbol'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      pricePerCoin: (json['pricePerCoin'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coinId': coinId,
      'coinSymbol': coinSymbol,
      'amount': amount,
      'date': date.toIso8601String(),
      'pricePerCoin': pricePerCoin,
    };
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      coinId: entity.coinId,
      coinSymbol: entity.coinSymbol,
      amount: entity.amount,
      date: entity.date,
      pricePerCoin: entity.pricePerCoin,
    );
  }
}
