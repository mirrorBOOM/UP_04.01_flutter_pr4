import 'package:go_router/go_router.dart';
import 'models/workout_query.dart';
import 'screens/workout_list_screen.dart';
import 'screens/workout_details_screen.dart';
import 'screens/trainer_list_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        final q = state.uri.queryParameters;
        final query = WorkoutQuery(
          search: q['search'] ?? '',
          trainerId: int.tryParse(q['trainerId'] ?? ''),
          page: int.tryParse(q['page'] ?? '') ?? 1,
          size: int.tryParse(q['size'] ?? '') ?? 10,
        );
        return WorkoutListScreen(initialQuery: query);
      },
    ),
    GoRoute(
      path: '/workouts/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
        return WorkoutDetailsScreen(workoutId: id);
      },
    ),
    GoRoute(
      path: '/trainers',
      builder: (context, state) => const TrainerListScreen(),
    ),
  ],
);