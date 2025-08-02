import 'package:cryptocurrency_tracker_app/core/error/exceptions.dart';
import 'package:cryptocurrency_tracker_app/core/services/coin_gecko_service.dart';
import 'package:cryptocurrency_tracker_app/core/theme/theme_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // Import for NumberFormat and DateFormat
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
    final dynamic rawWishlist = _wishlistBox.get('coinIds', defaultValue: []);
    final List<String> wishlistIds = List<String>.from(rawWishlist as List);
    return wishlistIds.contains(coinId);
  }

  void _toggleWishlist(String coinId) {
    final dynamic rawWishlist = _wishlistBox.get('coinIds', defaultValue: []);
    final List<String> wishlistIds = List<String>.from(rawWishlist as List);

    if (wishlistIds.contains(coinId)) {
      wishlistIds.remove(coinId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from Wishlist')),
      );
    } else {
      wishlistIds.add(coinId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to Wishlist')),
      );
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
            icon: Icon(
              themeProvider.mode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
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
          final bool inWishlist = _isInWishlist(coin.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, coin),
                const SizedBox(height: 24),
                _buildPriceChart(context, marketChart),
                const SizedBox(height: 24),
                _buildMarketStats(context, coin),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () => _toggleWishlist(coin.id),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          inWishlist ? Icons.favorite : Icons.favorite_border,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          inWishlist
                              ? 'Remove from Wishlist'
                              : 'Add to Wishlist',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Coin coin) {
    final priceChange = coin.priceChangePercentage24h;
    final priceChangeColor = priceChange >= 0 ? Colors.green : Colors.red;

    return Row(
      children: [
        Image.network(coin.image, width: 50, height: 50),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${coin.name} (${coin.symbol.toUpperCase()})',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              NumberFormat.currency(
                locale: 'en_US',
                symbol: '\$',
              ).format(coin.currentPrice),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: priceChangeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${priceChange.toStringAsFixed(2)}%',
            style: TextStyle(
              color: priceChangeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarketStats(BuildContext context, Coin coin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(
              context,
              'Market Cap',
              NumberFormat.compactCurrency(
                locale: 'en_US',
                symbol: '\$',
              ).format(coin.marketCap ?? 0),
            ),
            _buildStatItem(
              context,
              'Total Volume',
              NumberFormat.compactCurrency(
                locale: 'en_US',
                symbol: '\$',
              ).format(coin.totalVolume ?? 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPriceChart(
    BuildContext context,
    Map<String, dynamic> marketChart,
  ) {
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
      height: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1000 * 60 * 60 * 24 * 2, // ~2 days
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.fromMillisecondsSinceEpoch(
                        value.toInt(),
                      );
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(DateFormat.MMMd().format(date)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat.compact().format(value),
                        textAlign: TextAlign.left,
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
              minX: spots.first.x,
              maxX: spots.last.x,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final date = DateTime.fromMillisecondsSinceEpoch(
                        spot.x.toInt(),
                      );
                      return LineTooltipItem(
                        '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(spot.y)}\n',
                        TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: DateFormat('MMM d, yyyy').format(date),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object? error) {
    String message = 'An unexpected error occurred.';
    if (error is ApiException) {
      message = error.toString();
    } else if (error is String) {
      message = error;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}