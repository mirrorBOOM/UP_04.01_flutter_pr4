import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../repositories/persistent_workout_repository.dart';
import '../widgets/entity_table.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FitnessClubRepository>();
    final clients = repo.allClients;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Клиенты клуба (Карты 1:1)'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/clients/new'),
        icon: const Icon(Icons.person_add),
        label: const Text('Добавить клиента'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: clients.isEmpty
              ? const Center(child: Text('Список клиентов пуст'))
              : EntityTable<Client>(
                  items: clients,
                  idOf: (c) => c.id,
                  columns: [
                    TableColumnSpec(label: 'ФИО клиента', build: (c) => Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.bold))),
                    TableColumnSpec(label: 'Email', build: (c) => Text(c.email)),
                    TableColumnSpec(label: 'Телефон', build: (c) => Text(c.phone)),
                    TableColumnSpec(label: 'Клубная карта (1:1)', build: (c) => Chip(
                      label: Text('${c.card.cardNumber} (до ${c.card.validUntil})'),
                      backgroundColor: Colors.orange.shade50,
                    )),
                  ],
                  actions: (c) => [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Редактировать',
                      onPressed: () => context.go('/clients/${c.id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Удалить',
                      onPressed: () async {
                        await repo.deleteClient(c.id);
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