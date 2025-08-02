import 'package:hive/hive.dart';

part 'coin.g.dart';

@HiveType(typeId: 0)
class Coin extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String symbol;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String image;

  @HiveField(4)
  final double currentPrice;

  @HiveField(5)
  final double priceChangePercentage24h;

  @HiveField(6)
  final double? marketCap;

  @HiveField(7)
  final double? totalVolume;

  Coin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.currentPrice,
    required this.priceChangePercentage24h,
    this.marketCap,
    this.totalVolume,
  });

  factory Coin.fromJson(Map<String, dynamic> json) {
    return Coin(
      id: json['id'],
      symbol: json['symbol'],
      name: json['name'],
      image: json['image'],
      currentPrice: (json['current_price'] as num).toDouble(),
      priceChangePercentage24h: (json['price_change_percentage_24h'] as num).toDouble(),
      marketCap: (json['market_cap'] as num?)?.toDouble(),
      totalVolume: (json['total_volume'] as num?)?.toDouble(),
    );
  }
}
