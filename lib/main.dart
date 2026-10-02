import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'repositories/workout_repository.dart';
import 'repositories/persistent_workout_repository.dart';
import 'state/workout_list_notifier.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  final repo = FitnessClubRepository(prefs);

  runApp(
    MultiProvider(
      providers: [
        Provider<FitnessClubRepository>.value(value: repo),
        Provider<WorkoutRepository>.value(value: repo),
        ChangeNotifierProvider<WorkoutListNotifier>(
          create: (ctx) => WorkoutListNotifier(ctx.read<WorkoutRepository>())..load(),
        ),
      ],
      child: const FitnessClubApp(),
    ),
  );
}

class FitnessClubApp extends StatelessWidget {
  const FitnessClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Фитнес-клуб',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}