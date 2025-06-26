import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'app/theme.dart'; // Import tema medical

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    print('UNCAUGHT ASYNC ERROR:');
    print(error);
    print(stack);
    return true;
  };
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      routerConfig: router,
      title: 'Dopply - Medical Monitoring App',
      // Aplikasi tema medical yang menunjukkan profesionalitas dan integritas
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Default ke light theme
      debugShowCheckedModeBanner:
          false, // Hilangkan banner debug untuk tampilan lebih bersih
    );
  }
}
