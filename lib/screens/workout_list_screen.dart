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
      if (q.sortField.isNotEmpty) 'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
      'page': q.page.toString(),
      'size': q.size.toString(),
    };
    final uri = Uri(path: '/', queryParameters: params);
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<WorkoutListNotifier>();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Фитнес-клуб: Каталог тренировок'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Тренерский состав',
            onPressed: () => context.go('/trainers'),
          ),
          if (notifier.hasSelection)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              tooltip: 'Удалить выбранные (${notifier.selected.length})',
              onPressed: () => _confirmDelete(context, notifier),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Поиск (название / код)...',
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
                DropdownButton<int?>(
                  value: notifier.query.trainerId,
                  hint: const Text('Все тренеры'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Все тренеры')),
                    DropdownMenuItem(value: 1, child: Text('А. Ковалёв (CrossFit)')),
                    DropdownMenuItem(value: 2, child: Text('Е. Миронова (Йога)')),
                    DropdownMenuItem(value: 3, child: Text('Р. Багиров (Бокс)')),
                    DropdownMenuItem(value: 6, child: Text('М. Соколова (Бассейн)')),
                  ],
                  onChanged: (val) {
                    final next = notifier.query.copyWith(trainerId: val);
                    notifier.applyQuery(next);
                    _syncUrl(next);
                  },
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Включая архивные'),
                    Switch(
                      value: notifier.query.includeDeleted,
                      onChanged: (val) {
                        final next = notifier.query.copyWith(includeDeleted: val);
                        notifier.applyQuery(next);
                        _syncUrl(next);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: switch (notifier.status) {
              LoadStatus.loading => const Center(child: CircularProgressIndicator()),
              LoadStatus.error => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      Text(notifier.error ?? 'Ошибка'),
                      ElevatedButton(onPressed: () => notifier.load(), child: const Text('Повторить')),
                    ],
                  ),
                ),
              _ => notifier.result.items.isEmpty
                  ? const Center(child: Text('Ничего не найдено', style: TextStyle(fontSize: 16)))
                  : isMobile
                      ? _buildCards(notifier)
                      : _buildTable(notifier),
            },
          ),

          _buildPagination(notifier),
        ],
      ),
    );
  }

  Widget _buildTable(WorkoutListNotifier notifier) {
    return EntityTable<Workout>(
      items: notifier.result.items,
      idOf: (w) => w.id,
      selected: notifier.selected,
      onToggleSelect: (id) => notifier.toggleSelection(id),
      sortField: notifier.query.sortField,
      sortAscending: notifier.query.sortAscending,
      onSort: (field) {
        final asc = notifier.query.sortField == field ? !notifier.query.sortAscending : true;
        final next = notifier.query.copyWith(sortField: field, sortAscending: asc);
        notifier.applyQuery(next);
        _syncUrl(next);
      },
      columns: [
        TableColumnSpec(
          label: 'Направление',
          sortField: 'title',
          build: (w) => InkWell(
            onTap: () => context.go('/workouts/${w.id}'),
            child: Text(w.title, style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
              decoration: w.isDeleted ? TextDecoration.lineThrough : null,
            )),
          ),
        ),
        TableColumnSpec(label: 'Код', build: (w) => Text(w.code)),
        TableColumnSpec(label: 'Длительность', sortField: 'duration', numeric: true, build: (w) => Text('${w.durationMinutes} мин')),
        TableColumnSpec(label: 'Расход калорий', sortField: 'calories', numeric: true, build: (w) => Text('${w.caloriesBurned} ккал')),
        TableColumnSpec(label: 'Интенсивность', sortField: 'intensity', numeric: true, build: (w) => Text('${w.intensity}/5')),
        TableColumnSpec(label: 'Места', numeric: true, build: (w) => Text('${w.capacityAvailable}/${w.capacityTotal}')),
      ],
      actions: (w) => [
        if (w.isDeleted)
          IconButton(icon: const Icon(Icons.restore, color: Colors.green), onPressed: () => notifier.restore(w.id))
        else
          IconButton(icon: const Icon(Icons.delete, color: Colors.orange), onPressed: () => notifier.softDelete(w.id)),
      ],
    );
  }

  Widget _buildCards(WorkoutListNotifier notifier) {
    return ListView.builder(
      itemCount: notifier.result.items.length,
      itemBuilder: (ctx, i) {
        final w = notifier.result.items[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Checkbox(
              value: notifier.selected.contains(w.id),
              onChanged: (_) => notifier.toggleSelection(w.id),
            ),
            title: Text(w.title, style: TextStyle(decoration: w.isDeleted ? TextDecoration.lineThrough : null)),
            subtitle: Text('Код: ${w.code} | ${w.durationMinutes} мин | ${w.caloriesBurned} ккал'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.go('/workouts/${w.id}'),
          ),
        );
      },
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
                onPressed: res.hasPrevious ? () => notifier.applyQuery(notifier.query.copyWith(page: 1)) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: res.hasPrevious ? () => notifier.applyQuery(notifier.query.copyWith(page: res.page - 1)) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: res.hasNext ? () => notifier.applyQuery(notifier.query.copyWith(page: res.page + 1)) : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: res.hasNext ? () => notifier.applyQuery(notifier.query.copyWith(page: res.totalPages)) : null,
              ),
            ],
          )
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WorkoutListNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Удалить выбранные программы (${notifier.selected.length} шт.)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.deleteSelected();
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}