import '../../domain/entities/crypto_coin_entity.dart';

class CryptoCoinModel extends CryptoCoinEntity {
  const CryptoCoinModel({
    required super.id,
    required super.symbol,
    required super.name,
    required super.currentPrice,
    required super.priceChangePercentage24h,
    required super.image,
    super.genesisDate,
  });

  factory CryptoCoinModel.fromJson(Map<String, dynamic> json) {
    dynamic imageRaw = json['image'];
    String imageUrl = '';
    if (imageRaw is String) {
      imageUrl = imageRaw;
    } else if (imageRaw is Map) {
      imageUrl = imageRaw['large'] ?? imageRaw['small'] ?? '';
    }

    double price = (json['current_price'] as num?)?.toDouble() ?? 
                   (json['market_data']?['current_price']?['usd'] as num?)?.toDouble() ?? 0.0;
                   
    double change = (json['price_change_percentage_24h'] as num?)?.toDouble() ?? 
                    (json['market_data']?['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0;

    return CryptoCoinModel(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      currentPrice: price,
      priceChangePercentage24h: change,
      image: imageUrl,
      genesisDate: json['genesis_date'] != null ? DateTime.tryParse(json['genesis_date']) : null,
    );
  }
}
