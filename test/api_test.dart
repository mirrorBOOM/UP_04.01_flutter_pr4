import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:up_4001_pr2/core/api_exceptions.dart';
import 'package:up_4001_pr2/core/api_client.dart';
import 'package:up_4001_pr2/models/workout.dart';
import 'package:up_4001_pr2/models/workout_query.dart';
import 'package:up_4001_pr2/repositories/api_workout_repository.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late ApiWorkoutRepository repository;

  setUp(() {
    dio = buildDio();
    dioAdapter = DioAdapter(dio: dio);
    repository = ApiWorkoutRepository(dio);
  });

  test('1. Успешная загрузка списка тренировок с сервера', () async {
    dioAdapter.onGet(
      '/workouts',
      (server) => server.reply(200, {
        'items': [
          {'id': 1, 'title': 'Йога', 'code': 'YOG-1', 'durationMinutes': 60, 'caloriesBurned': 300, 'intensity': 2, 'hallId': 1, 'trainerId': 1, 'capacityTotal': 10, 'capacityAvailable': 5}
        ],
        'page': 1,
        'size': 10,
        'total': 1,
      }),
    );

    final res = await repository.find(const WorkoutQuery());
    expect(res.items.length, 1);
    expect(res.items.first.title, 'Йога');
  });

  test('2. Ошибка сервера 422 преобразуется в ValidationException', () async {
    dioAdapter.onPost(
      '/workouts',
      (server) => server.reply(422, {
        'message': 'Ошибка валидации',
        'errors': {'code': 'Артикул уже занят'},
      }),
      data: Matchers.any,
    );

    const workout = Workout(
      id: 999999,
      title: 'Бокс',
      code: 'BOX-DUP',
      durationMinutes: 60,
      caloriesBurned: 500,
      intensity: 4,
      hallId: 1,
      trainerId: 1,
      categoryIds: [],
      capacityTotal: 10,
      capacityAvailable: 10,
    );

    expect(
      () => repository.save(workout),
      throwsA(isA<ValidationException>().having((e) => e.errors['code'], 'code error', 'Артикул уже занят')),
    );
  });

  test('3. Ошибка недоступности сервера преобразуется в NetworkException', () async {
    dioAdapter.onGet(
      '/workouts',
      (server) => server.throws(
        500,
        DioException(
          requestOptions: RequestOptions(path: '/workouts'),
          type: DioExceptionType.connectionError,
        ),
      ),
    );

    expect(() => repository.find(const WorkoutQuery()), throwsA(isA<NetworkException>()));
  });

  test('4. Ошибка 404 преобразуется в NotFoundException', () async {
    dioAdapter.onGet('/workouts/999', (server) => server.reply(404, {'message': 'Тренировка не найдена'}));
    expect(() => repository.findById(999), throwsA(isA<NotFoundException>()));
  });

  test('5. Ошибка 409 преобразуется в ConflictException', () async {
    dioAdapter.onDelete('/workouts/1', (server) => server.reply(409, {'message': 'Нельзя удалить: есть активные записи'}));
    expect(() => repository.softDelete(1), throwsA(isA<ConflictException>()));
  });
}