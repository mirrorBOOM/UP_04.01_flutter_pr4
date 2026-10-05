import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/workout.dart';
import '../models/workout_query.dart';
import '../state/workout_list_notifier.dart';
import '../widgets/entity_table.dart';

class WorkoutListScreen extends StatefulWidget {
  final WorkoutQuery initialQuery;

  const WorkoutListScreen({super.key, required this.initialQuery});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery.search);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutListNotifier>().applyQuery(widget.initialQuery);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncUrl(WorkoutQuery q) {
    final params = <String, String>{
      if (q.search.isNotEmpty) 'search': q.search,
      if (q.trainerId != null) 'trainerId': q.trainerId.toString(),
      'page': q.page.toString(),
      'size': q.size.toString(),
    };
    context.go(Uri(path: '/', queryParameters: params).toString());
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<WorkoutListNotifier>();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Фитнес-клуб: Каталог'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Тренеры',
            onPressed: () => context.go('/trainers'),
          ),
          IconButton(
            icon: const Icon(Icons.badge),
            tooltip: 'Клиенты и карты (1:1)',
            onPressed: () => context.go('/clients'),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepOrange),
              child: Text(
                'Панель управления\nФитнес-клуба',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('1. Тренировки (Каталог)'),
              onTap: () { Navigator.pop(context); context.go('/'); },
            ),
            ListTile(
              leading: const Icon(Icons.sports),
              title: const Text('2. Тренеры клуба'),
              onTap: () { Navigator.pop(context); context.go('/trainers'); },
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room),
              title: const Text('3. Залы клуба (Связь 1:N)'),
              onTap: () { Navigator.pop(context); context.go('/halls'); },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('4. Категории фитнеса (Связь M:N)'),
              onTap: () { Navigator.pop(context); context.go('/categories'); },
            ),
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('5. Клиенты и карты (Связь 1:1)'),
              onTap: () { Navigator.pop(context); context.go('/clients'); },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/workouts/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить тренировку'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Поиск по названию или артикулу...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (text) {
                notifier.setSearchDebounced(text);
                _syncUrl(notifier.query.copyWith(search: text));
              },
            ),
          ),
          Expanded(
            child: switch (notifier.status) {
              LoadStatus.loading => const Center(child: CircularProgressIndicator()),
              LoadStatus.error => Center(child: Text(notifier.error ?? 'Ошибка')),
              _ => notifier.result.items.isEmpty
                  ? const Center(child: Text('Пусто'))
                  : isMobile
                      ? ListView.builder(
                          itemCount: notifier.result.items.length,
                          itemBuilder: (ctx, i) {
                            final w = notifier.result.items[i];
                            return ListTile(
                              title: Text(w.title),
                              subtitle: Text('${w.code} | Зал #${w.hallId}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => context.go('/workouts/${w.id}/edit'),
                              ),
                              onTap: () => context.go('/workouts/${w.id}'),
                            );
                          },
                        )
                      : EntityTable<Workout>(
                          items: notifier.result.items,
                          idOf: (w) => w.id,
                          columns: [
                            TableColumnSpec(label: 'Название', build: (w) => Text(w.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                            TableColumnSpec(label: 'Артикул', build: (w) => Text(w.code)),
                            TableColumnSpec(label: 'Зал ID', numeric: true, build: (w) => Text('${w.hallId}')),
                            TableColumnSpec(label: 'Категорий', numeric: true, build: (w) => Text('${w.categoryIds.length}')),
                          ],
                          actions: (w) => [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Редактировать',
                              onPressed: () => context.go('/workouts/${w.id}/edit'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.orange),
                              onPressed: () => notifier.softDelete(w.id),
                            ),
                          ],
                        ),
            },
          ),
          // ПАНЕЛЬ ПАГИНАЦИИ (п. 12, 13 ТЗ):
          _buildPagination(notifier),
        ],
      ),
    );
  }

  Widget _buildPagination(WorkoutListNotifier notifier) {
    final res = notifier.result;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Всего: ${res.total} | Стр. ${res.page} из ${res.totalPages}'),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: res.hasPrevious
                    ? () {
                        final next = notifier.query.copyWith(page: 1);
                        notifier.applyQuery(next);
                        _syncUrl(next);
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: res.hasPrevious
                    ? () {
                        final next = notifier.query.copyWith(page: res.page - 1);
                        notifier.applyQuery(next);
                        _syncUrl(next);
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: res.hasNext
                    ? () {
                        final next = notifier.query.copyWith(page: res.page + 1);
                        notifier.applyQuery(next);
                        _syncUrl(next);
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: res.hasNext
                    ? () {
                        final next = notifier.query.copyWith(page: res.totalPages);
                        notifier.applyQuery(next);
                        _syncUrl(next);
                      }
                    : null,
              ),
            ],
          )
        ],
      ),
    );
  }
}