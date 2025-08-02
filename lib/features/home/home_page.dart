import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:cryptocurrency_tracker_app/core/services/coin_gecko_service.dart';
import 'package:cryptocurrency_tracker_app/core/theme/theme_provider.dart';

class CoinListProvider extends ChangeNotifier {
  final CoinGeckoService _coinGeckoService = CoinGeckoService();
  List<Coin> _allCoins = [];
  List<Coin> _filteredCoins = [];
  bool _isLoading = false;
  int _page = 1;
  bool _hasMore = true;

  List<Coin> get allCoins => _allCoins;
  List<Coin> get filteredCoins => _filteredCoins;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> loadCoins() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    notifyListeners();

    try {
      final newCoins = await _coinGeckoService.fetchCoins(page: _page);
      if (newCoins.isEmpty) {
        _hasMore = false;
      } else {
        _allCoins.addAll(newCoins);
        _filteredCoins = List.from(
          _allCoins,
        ); // Initialize filteredCoins with allCoins
        _page++;
      }
    } catch (e) {
      // Handle error, e.g., show a snackbar
      print('Error loading coins: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterCoins(String query) {
    if (query.isEmpty) {
      _filteredCoins = List.from(_allCoins);
    } else {
      _filteredCoins =
          _allCoins
              .where(
                (coin) =>
                    coin.name.toLowerCase().contains(query.toLowerCase()) ||
                    coin.symbol.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    await loadCoins();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CoinListProvider>(context, listen: false).loadCoins();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !Provider.of<CoinListProvider>(context, listen: false).isLoading &&
          Provider.of<CoinListProvider>(context, listen: false).hasMore) {
        Provider.of<CoinListProvider>(context, listen: false).loadMore();
      }
    });

    _searchController.addListener(() {
      Provider.of<CoinListProvider>(
        context,
        listen: false,
      ).filterCoins(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cryptocurrency Tracker'),
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
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              context.push('/wishlist');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Coins',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: Consumer<CoinListProvider>(
              builder: (context, coinListProvider, child) {
                if (coinListProvider.isLoading &&
                    coinListProvider.allCoins.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                } else if (coinListProvider.filteredCoins.isEmpty &&
                    !coinListProvider.isLoading) {
                  return const Center(child: Text('No coins found.'));
                } else {
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        coinListProvider.filteredCoins.length +
                        (coinListProvider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == coinListProvider.filteredCoins.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final coin = coinListProvider.filteredCoins[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: Image.network(
                            coin.image,
                            width: 40,
                            height: 40,
                          ),
                          title: Text(
                            '${coin.name} (${coin.symbol.toUpperCase()})',
                          ),
                          subtitle: Text(
                            'Price: ${coin.currentPrice.toStringAsFixed(2)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color:
                                      coin.priceChangePercentage24h >= 0
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            context.push('/details/${coin.id}');
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
