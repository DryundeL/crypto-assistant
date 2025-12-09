import 'package:crypto_assistant/features/crypto/domain/entities/crypto_coin_entity.dart';
import 'package:crypto_assistant/features/crypto/presentation/viewmodels/home_viewmodel.dart';
import 'package:crypto_assistant/features/wallet/domain/entities/transaction_entity.dart';
import 'package:crypto_assistant/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:crypto_assistant/features/crypto/domain/repositories/i_crypto_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  CryptoCoinEntity? _selectedCoin;
  final _amountController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Pre-select first coin if available or handle empty state
    final homeViewModel = context.read<HomeViewModel>();
    if (homeViewModel.coins.isNotEmpty) {
      _selectedCoin = homeViewModel.coins.first;
      _priceController.text = _selectedCoin!.currentPrice.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeViewModel = context.watch<HomeViewModel>();
    final coins = homeViewModel.coins;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Coin Selection
            // Coin Selection
            InkWell(
              onTap: () => _showCoinSelection(context, coins),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Select Coin',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedCoin != null 
                            ? '${_selectedCoin!.name} (${_selectedCoin!.symbol.toUpperCase()})' 
                            : 'Select a coin',
                        style: TextStyle(
                          color: _selectedCoin != null 
                              ? Theme.of(context).textTheme.bodyLarge?.color 
                              : Theme.of(context).hintColor,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter amount';
                if (double.tryParse(value) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Price per Coin
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price per Coin'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter price';
                if (double.tryParse(value) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date Selection
            ListTile(
              title: const Text('Date'),
              subtitle: Text(_selectedDate.toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                if (_selectedCoin == null) return;

                DateTime firstDate = DateTime(2009);
                
                // If genesis date is unknown, fetch details
                if (_selectedCoin!.genesisDate == null) {
                  // Show loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checking coin details...'), duration: Duration(seconds: 1)),
                  );
                  
                  try {
                    final detailedCoin = await context.read<ICryptoRepository>().getCoinDetails(_selectedCoin!.id);
                    setState(() {
                      _selectedCoin = detailedCoin;
                      // Update price if needed, but usually we keep what user selected or current
                    });
                    if (detailedCoin.genesisDate != null) {
                      firstDate = detailedCoin.genesisDate!;
                    }
                  } catch (e) {
                    // Ignore error, use default
                  }
                } else {
                  firstDate = _selectedCoin!.genesisDate!;
                }

                if (!mounted) return;

                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: firstDate,
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                  _updatePrice();
                }
              },
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate() && _selectedCoin != null) {
      final amount = double.parse(_amountController.text);
      final price = double.parse(_priceController.text);

      final transaction = TransactionEntity(
        id: const Uuid().v4(),
        coinId: _selectedCoin!.id,
        coinSymbol: _selectedCoin!.symbol,
        amount: amount,
        date: _selectedDate,
        pricePerCoin: price,
      );

      context.read<WalletCubit>().addTransaction(transaction);
      Navigator.pop(context);
    }
  }


  void _showCoinSelection(BuildContext context, List<CryptoCoinEntity> coins) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CoinSelectionModal(
        coins: coins,
        onSelect: (coin) {
          setState(() {
            _selectedCoin = coin;
          });
          _updatePrice();
        },
      ),
    );
  }

  Future<void> _updatePrice() async {
    if (_selectedCoin == null) return;

    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    if (isToday) {
      setState(() {
        _priceController.text = _selectedCoin!.currentPrice.toString();
      });
    } else {
      setState(() {
        _priceController.text = 'Loading...';
      });

      try {
        final price = await context.read<ICryptoRepository>().getCoinPriceAtDate(
          _selectedCoin!.id,
          _selectedCoin!.symbol,
          _selectedDate,
          'usd'
        );

        if (price != null && mounted) {
          setState(() {
            _priceController.text = price.toString();
          });
        } else if (mounted) {
          setState(() {
            _priceController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not fetch historical price. Please enter manually.')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _priceController.clear();
          });
        }
      }
    }
  }
}

class _CoinSelectionModal extends StatefulWidget {
  final List<CryptoCoinEntity> coins;
  final Function(CryptoCoinEntity) onSelect;

  const _CoinSelectionModal({required this.coins, required this.onSelect});

  @override
  State<_CoinSelectionModal> createState() => _CoinSelectionModalState();
}

class _CoinSelectionModalState extends State<_CoinSelectionModal> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredCoins = widget.coins.where((coin) {
      final query = _searchQuery.toLowerCase();
      return coin.name.toLowerCase().contains(query) || 
             coin.symbol.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search coin...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCoins.length,
              itemBuilder: (context, index) {
                final coin = filteredCoins[index];
                return ListTile(
                  leading: Image.network(coin.image, width: 32, height: 32, errorBuilder: (_,__,___) => const Icon(Icons.circle)),
                  title: Text(coin.name),
                  subtitle: Text(coin.symbol.toUpperCase()),
                  onTap: () {
                    widget.onSelect(coin);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
