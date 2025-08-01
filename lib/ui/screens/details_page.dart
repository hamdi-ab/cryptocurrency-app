import 'package:flutter/material.dart';

class DetailsPage extends StatelessWidget {
  final String coinId;

  const DetailsPage({super.key, required this.coinId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Details for $coinId'),
      ),
      body: Center(
        child: Text('Details for coin ID: $coinId'),
      ),
    );
  }
}