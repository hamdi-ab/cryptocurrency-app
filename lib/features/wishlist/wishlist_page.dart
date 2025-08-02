import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/services/coin_gecko_service.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  late final Box<List<String>> _wishlistBox;
  List<Coin> _wishlistCoins = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _wishlistBox = Hive.box<List<String>>('wishlist');
    _loadWishlist();
    _wishlistBox.listenable().addListener(_loadWishlist);
  }

  Future<void> _loadWishlist() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dynamic rawWishlist = _wishlistBox.get('coinIds', defaultValue: []);
      final List<String> wishlistIds = List<String>.from(rawWishlist as List);

      if (wishlistIds.isEmpty) {
        if (mounted) {
          setState(() {
            _wishlistCoins = [];
            _isLoading = false;
          });
        }
        return;
      }

      final coinGeckoService = CoinGeckoService();
      final futureCoins =
          wishlistIds.map((id) => coinGeckoService.fetchCoinDetail(id)).toList();
      final resolvedCoins = await Future.wait(futureCoins);

      if (mounted) {
        setState(() {
          _wishlistCoins = resolvedCoins;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load wishlist: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFromWishlist(String coinId) async {
    final dynamic rawWishlist = _wishlistBox.get('coinIds', defaultValue: []);
    final List<String> wishlistIds = List<String>.from(rawWishlist as List);
    wishlistIds.remove(coinId);
    await _wishlistBox.put('coinIds', wishlistIds);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from wishlist!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _wishlistBox.listenable().removeListener(_loadWishlist);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadWishlist,
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      );
    }

    if (_wishlistCoins.isEmpty) {
      return const Center(
        child: Text(
          'No favorites yet.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _wishlistCoins.length,
      itemBuilder: (context, index) {
        final coin = _wishlistCoins[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(coin.image),
            backgroundColor: Colors.transparent,
          ),
          title: Text(coin.name),
          subtitle: Text(coin.symbol.toUpperCase()),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\$${coin.currentPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeFromWishlist(coin.id),
              ),
            ],
          ),
          onTap: () => context.push('/details/${coin.id}'),
        );
      },
    );
  }
}