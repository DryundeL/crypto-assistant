import 'package:crypto_assistant/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:crypto_assistant/features/wallet/presentation/pages/add_transaction_screen.dart';
import 'package:crypto_assistant/features/wallet/presentation/pages/coin_transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:crypto_assistant/features/settings/presentation/viewmodels/settings_viewmodel.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WalletCubit>().loadWallet();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currency = context.watch<SettingsViewModel>().currency;
    context.read<WalletCubit>().updateCurrency(currency);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        scrolledUnderElevation: 0,
        title: const Text('Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<WalletCubit, WalletState>(
        builder: (context, state) {
          if (state.status == WalletStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state.status == WalletStatus.failure) {
            return Center(child: Text('Failed to load wallet: ${state.errorMessage}'));
          }

          if (state.transactions.isEmpty) {
            return const Center(
              child: Text('No transactions yet. Add one to start tracking!'),
            );
          }

          final currencyCode = context.watch<SettingsViewModel>().currency;
          final currencyFormatter = NumberFormat.simpleCurrency(name: currencyCode.toUpperCase());
          final percentFormatter = NumberFormat.decimalPercentPattern(decimalDigits: 2);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Portfolio Summary Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text('Total Balance', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormatter.format(state.portfolioValue),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Profit/Loss', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                Text(
                                  currencyFormatter.format(state.totalProfitLoss),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: state.totalProfitLoss >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${state.totalProfitLossPercentage >= 0 ? '+' : ''}${percentFormatter.format(state.totalProfitLossPercentage / 100)})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: state.totalProfitLossPercentage >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            // We could add percentage here if we tracked total invested
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Your Assets', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // Asset List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.coinHoldings.length,
                  itemBuilder: (context, index) {
                    final coinId = state.coinHoldings.keys.elementAt(index);
                    final amount = state.coinHoldings[coinId]!;
                    final value = state.coinValues[coinId]!;
                    final profit = state.coinProfits[coinId]!;
                    final profitPercent = state.coinProfitPercentages[coinId]!;
                    
                    // Find coin info from transactions (not ideal, but works for now)
                    final transaction = state.transactions.firstWhere((t) => t.coinId == coinId);
                    final symbol = transaction.coinSymbol;
                    // We need image URL. In a real app we'd have a better way to get coin details.
                    // For now, we can try to find it in the HomeViewModel if available, or just show icon.
                    // But we don't have access to HomeViewModel easily here without passing it or looking it up.
                    // Let's use a simple circle avatar with symbol for now, or try to look up if we can.
                    
                    // Better approach: The WalletCubit should probably provide coin details or we fetch them.
                    // For this task, let's just use the symbol in a CircleAvatar if we can't get the image easily,
                    // OR we can try to construct the image URL if we know the ID (CoinGecko style), but that's flaky.
                    // Let's check if we can get it from the transaction entity if we added it there? No.
                    
                    // Let's just use a CircleAvatar with the first letter for now, as we don't have the image URL stored in WalletState easily
                    // without fetching coin details.
                    // WAIT, the user specifically asked for "icons error".
                    // I should probably store the image URL in the TransactionEntity or fetch it.
                    // Let's update TransactionEntity to store image URL? No, that requires data migration.
                    // Let's try to find the coin in the HomeViewModel provider since it's likely loaded.
                    
                    final imageUrl = state.coinImages[symbol.toLowerCase()];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: imageUrl != null 
                            ? Image.network(imageUrl, width: 40, height: 40, errorBuilder: (_,__,___) => CircleAvatar(
                                backgroundColor: Colors.deepPurple,
                                child: Text(symbol[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                              ))
                            : CircleAvatar(
                                backgroundColor: Colors.deepPurple,
                                child: Text(symbol[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                              ),
                        title: Text(symbol.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${amount.toStringAsFixed(4)} $symbol'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currencyFormatter.format(value), style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              '${profit >= 0 ? '+' : ''}${currencyFormatter.format(profit)} (${profitPercent >= 0 ? '+' : ''}${percentFormatter.format(profitPercent / 100)})',
                              style: TextStyle(
                                color: profit >= 0 ? Colors.green : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CoinTransactionsScreen(
                                coinId: coinId,
                                coinSymbol: symbol,
                                currentPrice: value / amount,
                                currencyCode: currencyCode,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
