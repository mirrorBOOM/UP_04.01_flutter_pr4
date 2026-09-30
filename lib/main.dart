import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'repositories/workout_repository.dart';
import 'repositories/in_memory_workout_repository.dart';
import 'repositories/trainer_repository.dart';
import 'state/workout_list_notifier.dart';
import 'router.dart';

void main() {
  usePathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        Provider<WorkoutRepository>(create: (_) => InMemoryWorkoutRepository()),
        Provider<TrainerRepository>(create: (_) => InMemoryTrainerRepository()),
        ChangeNotifierProvider<WorkoutListNotifier>(
          create: (ctx) => WorkoutListNotifier(ctx.read<WorkoutRepository>()),
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