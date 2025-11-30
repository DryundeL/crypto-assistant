import '../../domain/entities/crypto_coin_entity.dart';

class CryptoCoinModel extends CryptoCoinEntity {
  const CryptoCoinModel({
    required super.id,
    required super.symbol,
    required super.name,
    required super.currentPrice,
    required super.priceChangePercentage24h,
    required super.image,
  });

  factory CryptoCoinModel.fromJson(Map<String, dynamic> json) {
    return CryptoCoinModel(
      id: json['id'],
      symbol: json['symbol'],
      name: json['name'],
      currentPrice: (json['current_price'] as num).toDouble(),
      priceChangePercentage24h: (json['price_change_percentage_24h'] as num).toDouble(),
      image: json['image'],
    );
  }
}
