import 'package:flutter/material.dart';
import '../../domain/entities/crypto_coin_entity.dart';
import '../../domain/entities/recommendation_entity.dart';

class CryptoListTile extends StatelessWidget {
  final CryptoCoinEntity coin;

  const CryptoListTile({super.key, required this.coin});

  @override
  Widget build(BuildContext context) {
    final isPositive = coin.priceChangePercentage24h >= 0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          backgroundImage: NetworkImage(coin.image),
        ),
        title: Text(
          coin.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(coin.symbol.toUpperCase()),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${coin.currentPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${isPositive ? '+' : ''}${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecommendationModal extends StatelessWidget {
  final RecommendationEntity recommendation;

  const RecommendationModal({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Text(
                'AI Recommendation for Today',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(recommendation.coin.image),
                  backgroundColor: Colors.transparent,
                ),
                const SizedBox(height: 8),
                Text(
                  recommendation.coin.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  recommendation.coin.symbol.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            context,
            'Confidence Score',
            '${(recommendation.confidenceScore * 100).toStringAsFixed(1)}%',
            Colors.green,
          ),
          const SizedBox(height: 16),
          const Text(
            'Why this coin?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.reason,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                const Icon(Icons.water, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Whale Activity',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        recommendation.whaleActivitySummary,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Got it!'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
