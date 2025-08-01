import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:cryptocurrency_tracker_app/core/services/coin_gecko_service.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  late Box<List<String>> _wishlistBox;
  List<Coin> _wishlistCoins = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _wishlistBox = Hive.box<List<String>>('wishlist');
    _loadWishlistCoins();
  }

  Future<void> _loadWishlistCoins() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<String> coinIds = _wishlistBox.get('coinIds', defaultValue: [])!;
      List<Coin> fetchedCoins = [];
      for (String id in coinIds) {
        final coinDetail = await CoinGeckoService().fetchCoinDetail(id);
        fetchedCoins.add(coinDetail);
      }
      setState(() {
        _wishlistCoins = fetchedCoins;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load wishlist: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeFromWishlist(String coinId) {
    List<String> wishlist = List.from(_wishlistBox.get('coinIds', defaultValue: [])!);
    wishlist.remove(coinId);
    _wishlistBox.put('coinIds', wishlist);
    _loadWishlistCoins(); // Reload the list after removal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed from Wishlist')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      ElevatedButton(
                        onPressed: _loadWishlistCoins,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _wishlistCoins.isEmpty
                  ? const Center(child: Text('Your wishlist is empty.'))
                  : ListView.builder(
                      itemCount: _wishlistCoins.length,
                      itemBuilder: (context, index) {
                        final coin = _wishlistCoins[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            leading: Image.network(coin.image, width: 40, height: 40),
                            title: Text('${coin.name} (${coin.symbol.toUpperCase()})'),
                            subtitle: Text(
                              'Price: \$${coin.currentPrice.toStringAsFixed(2)}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeFromWishlist(coin.id),
                            ),
                            onTap: () {
                              context.push('/details/${coin.id}');
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}