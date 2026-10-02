import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/workout_category.dart';
import '../repositories/persistent_workout_repository.dart';
import '../widgets/entity_table.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  void _showCategoryDialog([WorkoutCategory? category]) {
    final isEditing = category != null;
    final nameCtrl = TextEditingController(text: category?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Редактировать категорию' : 'Новая категория фитнеса'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Название категории', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final repo = context.read<FitnessClubRepository>();
              await repo.saveCategory(WorkoutCategory(
                id: isEditing ? category.id : (DateTime.now().millisecondsSinceEpoch ~/ 1000),
                name: nameCtrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FitnessClubRepository>();
    final categories = repo.allCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Категории фитнеса (Связь M:N)'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Добавить категорию'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: EntityTable<WorkoutCategory>(
            items: categories,
            idOf: (c) => c.id,
            columns: [
              TableColumnSpec(label: 'ID', numeric: true, build: (c) => Text('${c.id}')),
              TableColumnSpec(label: 'Название категории', build: (c) => Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
            actions: (c) => [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                tooltip: 'Редактировать категорию',
                onPressed: () => _showCategoryDialog(c),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Удалить категорию',
                onPressed: () async {
                  await repo.deleteCategory(c.id);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}