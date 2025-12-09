import 'package:crypto_assistant/features/wallet/domain/entities/transaction_entity.dart';
import 'package:crypto_assistant/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CoinTransactionsScreen extends StatelessWidget {
  final String coinId;
  final String coinSymbol;
  final double currentPrice;
  final String currencyCode;

  const CoinTransactionsScreen({
    super.key,
    required this.coinId,
    required this.coinSymbol,
    required this.currentPrice,
    this.currencyCode = 'usd',
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.simpleCurrency(name: currencyCode.toUpperCase());
    final percentFormatter = NumberFormat.decimalPercentPattern(decimalDigits: 2);
    final dateFormatter = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('${coinSymbol.toUpperCase()} Transactions'),
      ),
      body: BlocBuilder<WalletCubit, WalletState>(
        builder: (context, state) {
          final transactions = state.transactions
              .where((t) => t.coinId == coinId || t.coinSymbol.toLowerCase() == coinSymbol.toLowerCase())
              .toList();

          // Sort by date descending
          transactions.sort((a, b) => b.date.compareTo(a.date));

          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final cost = transaction.amount * transaction.pricePerCoin;
              final currentValue = transaction.amount * currentPrice;
              final profit = currentValue - cost;
              final profitPercent = cost > 0 ? (profit / cost) : 0.0;

              return Dismissible(
                key: Key(transaction.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm"),
                        content: const Text("Are you sure you want to delete this transaction?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  context.read<WalletCubit>().deleteTransaction(transaction.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction deleted')),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateFormatter.format(transaction.date),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '${transaction.amount} ${coinSymbol.toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cost Basis:', style: TextStyle(color: Colors.grey)),
                            Text(currencyFormatter.format(transaction.pricePerCoin)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Current Price:', style: TextStyle(color: Colors.grey)),
                            Text(currencyFormatter.format(currentPrice)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Profit/Loss:', style: TextStyle(fontWeight: FontWeight.w500)),
                            Row(
                              children: [
                                Text(
                                  '${profit >= 0 ? '+' : ''}${currencyFormatter.format(profit)}',
                                  style: TextStyle(
                                    color: profit >= 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${profitPercent >= 0 ? '+' : ''}${percentFormatter.format(profitPercent)})',
                                  style: TextStyle(
                                    color: profitPercent >= 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
