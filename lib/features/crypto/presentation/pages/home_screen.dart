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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crypto Assistant'),
        actions: [
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
              itemCount: viewModel.coins.length,
              itemBuilder: (context, index) {
                return CryptoListTile(coin: viewModel.coins[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
