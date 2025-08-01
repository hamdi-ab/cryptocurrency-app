import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:cryptocurrency_tracker_app/routes/app_router.dart';
import 'package:cryptocurrency_tracker_app/models/coin_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();

  // Register Hive Adapters
  // Hive.registerAdapter(CoinAdapter()); // Uncomment and implement CoinAdapter

  runApp(
    MultiProvider(
      providers: [
        // Add your providers here
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AppRouter appRouter = AppRouter();

    return MaterialApp.router(
      title: 'Cryptocurrency Tracker',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
      ),
      routerConfig: appRouter.router,
    );
  }
}