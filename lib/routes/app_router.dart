
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../models/coin_adapter.dart';
import '../features/details/details_page.dart';
import '../features/home/home_page.dart';
import '../features/wishlist/wishlist_page.dart';
import '../features/splash/splash_page.dart';

class AppRouter {
  final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) => const SplashPage(),
      ),
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) => const HomePage(),
      ),
      GoRoute(
        path: '/details/:id',
        builder: (BuildContext context, GoRouterState state) {
          final String id = state.pathParameters['id']!;
          return DetailsPage(coinId: id);
        },
      ),
      GoRoute(
        path: '/wishlist',
        builder: (BuildContext context, GoRouterState state) => const WishlistPage(),
      ),
    ],
  );
}
