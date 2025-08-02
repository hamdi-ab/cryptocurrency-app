import 'dart:convert';
import 'dart:io'; // For SocketException
import 'package:intl/intl.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:cryptocurrency_tracker_app/core/error/exceptions.dart';

class Coin {
  final String id;
  final String symbol;
  final String name;
  final String image;
  final double currentPrice;
  final double priceChangePercentage24h;
  final double? marketCap;
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

  // For parsing the list from /coins/markets
  factory Coin.fromJson(Map<String, dynamic> json) {
    return Coin(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      priceChangePercentage24h:
          (json['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0,
      marketCap: (json['market_cap'] as num?)?.toDouble(),
      totalVolume: (json['total_volume'] as num?)?.toDouble(),
    );
  }

  // For parsing the detailed response from /coins/{id}
  factory Coin.fromDetailJson(Map<String, dynamic> json) {
    final marketData = json['market_data'];
    return Coin(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      image: json['image']?['large'] ?? '', // Image is nested
      currentPrice: (marketData['current_price']?['usd'] as num?)?.toDouble() ?? 0.0,
      priceChangePercentage24h:
          (marketData['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0,
      marketCap: (marketData['market_cap']?['usd'] as num?)?.toDouble(),
      totalVolume: (marketData['total_volume']?['usd'] as num?)?.toDouble(),
    );
  }
}

class CoinGeckoService {
  static final CoinGeckoService _instance = CoinGeckoService._internal();
  factory CoinGeckoService() => _instance;

  CoinGeckoService._internal();

  final String _baseUrl = dotenv.env['COINGECKO_API_BASE']!;

  Future<List<Coin>> fetchCoins({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=20&page=$page',
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Coin.fromJson(json)).toList();
      } else if (response.statusCode == 429) {
        throw TooManyRequestsException();
      } else {
        throw ServerException('Failed to load coins: ${response.statusCode}');
      }
    } on SocketException {
      throw NetworkException();
    }
  }

  Future<Coin> fetchCoinDetail(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/coins/$id'));

      if (response.statusCode == 200) {
        return Coin.fromDetailJson(json.decode(response.body));
      } else if (response.statusCode == 429) {
        throw TooManyRequestsException();
      } else {
        throw ServerException('Failed to load coin details: ${response.statusCode}');
      }
    } on SocketException {
      throw NetworkException();
    }
  }

  Future<Map<String, dynamic>> fetchCoinMarketChart(
    String id, {
    int days = 7,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/coins/$id/market_chart?vs_currency=usd&days=$days'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 429) {
        throw TooManyRequestsException();
      } else {
        throw ServerException('Failed to load coin market chart: ${response.statusCode}');
      }
    } on SocketException {
      throw NetworkException();
    }
  }
}