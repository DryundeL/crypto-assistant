import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeViewModel>(context, listen: false).loadCoins();
    });
  }

  Future<void> _showRecommendation(BuildContext context) async {
    final viewModel = Provider.of<HomeViewModel>(context, listen: false);
    
    // Trigger loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final locale = Localizations.localeOf(context).languageCode;
    await viewModel.getRecommendation(locale);

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (viewModel.recommendation != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => RecommendationModal(recommendation: viewModel.recommendation!),
      );
    } else if (viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        scrolledUnderElevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search coins...',
                  hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  Provider.of<HomeViewModel>(context, listen: false).searchCoins(value);
                },
              )
            : const Text('Crypto Assistant'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  Provider.of<HomeViewModel>(context, listen: false).searchCoins('');
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'Get AI Recommendation',
              onPressed: () => _showRecommendation(context),
            ),
          ],
        ],
      ),
      body: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.state == HomeState.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (viewModel.state == HomeState.error) {
            return Center(child: Text('Error: ${viewModel.errorMessage}'));
          } else if (viewModel.coins.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.loadCoins(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
              itemCount: viewModel.coins.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CryptoListTile(coin: viewModel.coins[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
