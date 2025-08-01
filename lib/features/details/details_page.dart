import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cryptocurrency_tracker_app/core/services/coin_gecko_service.dart';

class DetailsPage extends StatefulWidget {
  final String coinId;

  const DetailsPage({super.key, required this.coinId});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late Future<Map<String, dynamic>> _coinDetailsFuture;
  late Box<List<String>> _wishlistBox;

  @override
  void initState() {
    super.initState();
    _wishlistBox = Hive.box<List<String>>('wishlist');
    _fetchData();
  }

  void _fetchData() {
    _coinDetailsFuture = Future.wait([
      CoinGeckoService().fetchCoinDetail(widget.coinId),
      CoinGeckoService().fetchCoinMarketChart(widget.coinId, days: 7),
    ]).then((results) => {
          'coinDetail': results[0],
          'priceHistory': results[1],
        });
  }

  bool _isInWishlist(String coinId) {
    final List<String> wishlist = _wishlistBox.get('coinIds', defaultValue: [])!;
    return wishlist.contains(coinId);
  }

  void _toggleWishlist(String coinId) {
    List<String> wishlist = List.from(_wishlistBox.get('coinIds', defaultValue: [])!);
    if (wishlist.contains(coinId)) {
      wishlist.remove(coinId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from Wishlist')),
      );
    } else {
      wishlist.add(coinId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to Wishlist')),
      );
    }
    _wishlistBox.put('coinIds', wishlist);
    setState(() {}); // Rebuild to update wishlist icon
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Details'),
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: _coinDetailsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                final coinDetail = snapshot.data!['coinDetail'];
                return IconButton(
                  icon: Icon(
                    _isInWishlist(coinDetail.id) ? Icons.favorite : Icons.favorite_border,
                  ),
                  onPressed: () => _toggleWishlist(coinDetail.id),
                );
              }
              return Container();
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _coinDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: _fetchData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final coinDetail = snapshot.data!['coinDetail'];
            final List<dynamic> priceHistory = snapshot.data!['priceHistory']['prices'];

            List<FlSpot> spots = priceHistory.map((point) {
              return FlSpot(point[0].toDouble(), point[1].toDouble());
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${coinDetail.name} (${coinDetail.symbol.toUpperCase()})',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current Price: \$${coinDetail.currentPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Market Cap: \$${coinDetail.marketCap?.toStringAsFixed(2) ?? 'N/A'}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '7-Day Price History',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: const Color(0xff37434d), width: 1),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No data available.'));
          }
        },
      ),
    );
  }
}
