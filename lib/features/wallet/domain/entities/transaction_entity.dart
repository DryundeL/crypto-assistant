import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String id;
  final String coinId;
  final String coinSymbol;
  final double amount;
  final DateTime date;
  final double pricePerCoin;

  const TransactionEntity({
    required this.id,
    required this.coinId,
    required this.coinSymbol,
    required this.amount,
    required this.date,
    required this.pricePerCoin,
  });

  double get totalValue => amount * pricePerCoin;

  @override
  List<Object?> get props => [id, coinId, coinSymbol, amount, date, pricePerCoin];
}
