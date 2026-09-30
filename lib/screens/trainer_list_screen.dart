import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/trainer.dart';
import '../repositories/trainer_repository.dart';
import '../widgets/entity_table.dart';

class TrainerListScreen extends StatelessWidget {
  const TrainerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TrainerRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренерский состав клуба'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: FutureBuilder(
        future: repo.find(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!.items;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: EntityTable<Trainer>(
                items: items,
                idOf: (t) => t.id,
                columns: [
                  TableColumnSpec(label: 'ФИО тренера', build: (t) => Text(t.fullName, style: const TextStyle(fontWeight: FontWeight.bold))),
                  TableColumnSpec(label: 'Специализация', build: (t) => Text(t.specialization)),
                  TableColumnSpec(label: 'Категория', build: (t) => Text(t.category)),
                  TableColumnSpec(label: 'Опыт (лет)', numeric: true, build: (t) => Text('${t.experienceYears}')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}