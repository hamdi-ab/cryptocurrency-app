import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Coin {
  final String id;
  final String symbol;
  final String name;
  final String image;
  final double currentPrice;
  final double priceChangePercentage24h;

  Coin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.currentPrice,
    required this.priceChangePercentage24h,
  });

  factory Coin.fromJson(Map<String, dynamic> json) {
    return Coin(
      id: json['id'],
      symbol: json['symbol'],
      name: json['name'],
      image: json['image'],
      currentPrice: (json['current_price'] as num).toDouble(),
      priceChangePercentage24h: (json['price_change_percentage_24h'] as num).toDouble(),
    );
  }
}

class CoinGeckoService {
  static final CoinGeckoService _instance = CoinGeckoService._internal();
  factory CoinGeckoService() => _instance;

  CoinGeckoService._internal();

  final String _baseUrl = dotenv.env['COINGECKO_API_BASE']!;

  Future<List<Coin>> fetchCoins({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=20&page=\$page'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Coin.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load coins: \${response.statusCode}');
    }
  }
}
