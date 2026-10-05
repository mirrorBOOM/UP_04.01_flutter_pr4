import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api_client.dart';
import 'repositories/workout_repository.dart';
import 'repositories/api_workout_repository.dart';
import 'repositories/persistent_workout_repository.dart';
import 'state/workout_list_notifier.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  final localRepo = FitnessClubRepository(prefs);

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>(create: (_) => buildDio()),

        ProxyProvider<Dio, WorkoutRepository>(
          update: (_, dio, __) => ApiWorkoutRepository(dio),
        ),

        Provider<FitnessClubRepository>.value(value: localRepo),

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
      title: 'Фитнес-клуб API',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}