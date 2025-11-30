class CryptoCoinEntity {
  final String id;
  final String symbol;
  final String name;
  final double currentPrice;
  final double priceChangePercentage24h;
  final String image;

  const CryptoCoinEntity({
    required this.id,
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.priceChangePercentage24h,
    required this.image,
  });
}
