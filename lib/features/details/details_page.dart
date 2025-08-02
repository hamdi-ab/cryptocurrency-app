import 'package:cryptocurrency_tracker_app/core/error/exceptions.dart';
import 'package:cryptocurrency_tracker_app/core/services/coin_gecko_service.dart';
import 'package:cryptocurrency_tracker_app/core/theme/theme_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Helper class to hold the combined results of our API calls
class CoinDetailBundle {
  final Coin coin;
  final Map<String, dynamic> marketChart;

  CoinDetailBundle({required this.coin, required this.marketChart});
}

class DetailsPage extends StatefulWidget {
  final String coinId;

  const DetailsPage({super.key, required this.coinId});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late Future<CoinDetailBundle> _detailsFuture;
  late Box<List<String>> _wishlistBox;

  @override
  void initState() {
    super.initState();
    _wishlistBox = Hive.box<List<String>>('wishlist');
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _detailsFuture = _fetchAllDetails();
    });
  }

  Future<CoinDetailBundle> _fetchAllDetails() async {
    // No need for a try-catch block here, FutureBuilder handles it.
    final results = await Future.wait([
      CoinGeckoService().fetchCoinDetail(widget.coinId),
      CoinGeckoService().fetchCoinMarketChart(widget.coinId, days: 7),
    ]);

    return CoinDetailBundle(
      coin: results[0] as Coin,
      marketChart: results[1] as Map<String, dynamic>,
    );
  }

  bool _isInWishlist(String coinId) {
    final wishlistIds = _wishlistBox.get('coinIds', defaultValue: [])!;
    return wishlistIds.contains(coinId);
  }

  void _toggleWishlist(String coinId) {
    final List<String> wishlistIds = List.from(
      _wishlistBox.get('coinIds', defaultValue: [])!,
    );

    if (wishlistIds.contains(coinId)) {
      wishlistIds.remove(coinId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from Wishlist')));
    } else {
      wishlistIds.add(coinId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to Wishlist')));
    }
    _wishlistBox.put('coinIds', wishlistIds);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Details'),
        actions: [
          IconButton(
            icon: Icon(themeProvider.mode == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
          FutureBuilder<CoinDetailBundle>(
            future: _detailsFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return IconButton(
                  icon: Icon(
                    _isInWishlist(widget.coinId)
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                  onPressed: () => _toggleWishlist(widget.coinId),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<CoinDetailBundle>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // Handle custom exceptions
            if (snapshot.error is ApiException) {
              return _buildErrorWidget(snapshot.error.toString());
            } else {
              // Generic error for unexpected issues
              return _buildErrorWidget('An unexpected error occurred.');
            }
          }

          if (!snapshot.hasData) {
            return _buildErrorWidget('No data available.');
          }

          final coin = snapshot.data!.coin;
          final marketChart = snapshot.data!.marketChart;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${coin.name} (${coin.symbol.toUpperCase()})',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current Price: \${coin.currentPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Market Cap: \${coin.marketCap?.toStringAsFixed(2) ?? '
                  '}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                const Text(
                  '7-Day Price History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildPriceChart(marketChart),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildPriceChart(Map<String, dynamic> marketChart) {
    final List<dynamic>? priceHistory = marketChart['prices'];

    if (priceHistory == null || priceHistory.isEmpty) {
      return const Center(
        child: Text('Price history is currently unavailable.'),
      );
    }

    final List<FlSpot> spots =
        priceHistory.map((point) {
          return FlSpot(point[0].toDouble(), point[1].toDouble());
        }).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: true),
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
    );
  }
}
