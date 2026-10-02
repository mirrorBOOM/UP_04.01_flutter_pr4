import 'package:go_router/go_router.dart';
import 'models/workout_query.dart';
import 'screens/workout_list_screen.dart';
import 'screens/workout_details_screen.dart';
import 'screens/trainer_list_screen.dart';
import 'screens/trainer_form_screen.dart';
import 'screens/workout_form_screen.dart';
import 'screens/client_list_screen.dart';
import 'screens/client_form_screen.dart';
import 'screens/gym_halls_screen.dart';
import 'screens/categories_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return WorkoutListScreen(
          initialQuery: WorkoutQuery(
            search: q['search'] ?? '',
            trainerId: int.tryParse(q['trainerId'] ?? ''),
          ),
        );
      },
    ),
    GoRoute(
      path: '/workouts/new',
      builder: (context, state) => const WorkoutFormScreen(),
    ),
    GoRoute(
      path: '/workouts/:id/edit',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return WorkoutFormScreen(id: id);
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
    GoRoute(
      path: '/trainers/new',
      builder: (context, state) => const TrainerFormScreen(),
    ),
    GoRoute(
      path: '/trainers/:id/edit',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return TrainerFormScreen(id: id);
      },
    ),
    GoRoute(
      path: '/clients',
      builder: (context, state) => const ClientListScreen(),
    ),
    GoRoute(
      path: '/clients/new',
      builder: (context, state) => const ClientFormScreen(),
    ),
    GoRoute(
      path: '/clients/:id/edit',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return ClientFormScreen(id: id);
      },
    ),
    GoRoute(
      path: '/halls',
      builder: (context, state) => const GymHallsScreen(),
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoriesScreen(),
    ),
  ],
);