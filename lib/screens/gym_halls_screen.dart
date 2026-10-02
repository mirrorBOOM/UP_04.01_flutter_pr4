import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/gym_hall.dart';
import '../repositories/persistent_workout_repository.dart';
import '../widgets/entity_table.dart';

class GymHallsScreen extends StatefulWidget {
  const GymHallsScreen({super.key});

  @override
  State<GymHallsScreen> createState() => _GymHallsScreenState();
}

class _GymHallsScreenState extends State<GymHallsScreen> {
  void _showHallDialog([GymHall? hall]) {
    final isEditing = hall != null;
    final nameCtrl = TextEditingController(text: hall?.name ?? '');
    final capCtrl = TextEditingController(text: hall?.capacity.toString() ?? '20');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Редактировать зал' : 'Новый зал клуба'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Название зала', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: capCtrl, decoration: const InputDecoration(labelText: 'Вместимость (чел)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final repo = context.read<FitnessClubRepository>();
              await repo.saveHall(GymHall(
                id: isEditing ? hall.id : (DateTime.now().millisecondsSinceEpoch ~/ 1000),
                name: nameCtrl.text.trim(),
                capacity: int.tryParse(capCtrl.text) ?? 20,
              ));
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(isEditing ? 'Сохранить' : 'Добавить'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteHall(GymHall hall) async {
    final repo = context.read<FitnessClubRepository>();
    final count = repo.countWorkoutsInHall(hall.id);

    if (count > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Отказ в удалении зала'),
          content: Text('Невозможно удалить зал «${hall.name}»: к нему привязано активных тренировок: $count шт.\nСначала перенесите или удалите эти тренировки.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Понятно'))],
        ),
      );
    } else {
      await repo.deleteHall(hall.id);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FitnessClubRepository>();
    final halls = repo.allHalls;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Залы клуба (Связь 1:N)'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showHallDialog(),
        icon: const Icon(Icons.add_business),
        label: const Text('Добавить зал'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: EntityTable<GymHall>(
            items: halls,
            idOf: (h) => h.id,
            columns: [
              TableColumnSpec(label: 'Название зала', build: (h) => Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold))),
              TableColumnSpec(label: 'Вместимость', numeric: true, build: (h) => Text('${h.capacity} чел.')),
              TableColumnSpec(label: 'Тренировок в зале', numeric: true, build: (h) => Text('${repo.countWorkoutsInHall(h.id)}')),
            ],
            actions: (h) => [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                tooltip: 'Редактировать зал',
                onPressed: () => _showHallDialog(h),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Удалить зал',
                onPressed: () => _handleDeleteHall(h),
              ),
            ],
          ),
        ),
      ),
    );
  }
}