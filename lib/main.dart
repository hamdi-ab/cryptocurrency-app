import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:cryptocurrency_tracker_app/routes/app_router.dart';
import 'package:cryptocurrency_tracker_app/models/coin_adapter.dart';
import 'package:cryptocurrency_tracker_app/features/home/home_page.dart';
import 'package:cryptocurrency_tracker_app/core/theme/theme_provider.dart';

final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Hive.openBox<List<String>>('wishlist');

  // Register Hive Adapters
  // Hive.registerAdapter(CoinAdapter()); // Uncomment and implement CoinAdapter

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CoinListProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter appRouter;

  @override
  void initState() {
    super.initState();
    appRouter = AppRouter();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    ErrorWidget.builder = (FlutterErrorDetails details) {
      debugPrint(details.toString());
      return const Material(
        child: Center(
          child: Text(
            'Something went wrong!\nPlease try again later.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    };

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Crypto Tracker',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
      ),
      themeMode: themeProvider.mode,
      routerConfig: appRouter.router,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            ValueListenableBuilder<bool>(
              valueListenable: isLoadingNotifier,
              builder: (context, isLoading, _) {
                if (isLoading) {
                  return const Material(
                    color: Colors.black54,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        );
      },
    );
  }
}
