import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/admin_providers.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class AdminProgramsSection extends ConsumerWidget {
  const AdminProgramsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(adminProgramsProvider);
    final batches = ref.watch(adminBatchesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const TabBar(
          tabs: [
            Tab(text: 'Programs'),
            Tab(text: 'Batches'),
          ],
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
        ),
        body: TabBarView(
          children: [
            // Programs tab
            Scaffold(
              body: programs.when(
                data: (list) => list.isEmpty
                    ? const Center(child: Text('No programs yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final p = list[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(
                                p.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${p.type} · ${p.totalTerms} terms',
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: p.isActive
                                      ? AppColors.successLight
                                      : AppColors.dangerLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  p.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: p.isActive
                                        ? AppColors.success
                                        : AppColors.danger,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                loading: () => const LoadingWidget(),
                error: (e, _) => AppErrorWidget(message: e.toString()),
              ),
              floatingActionButton: FloatingActionButton(
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _showAddProgram(context, ref),
              ),
            ),

            // Batches tab
            Scaffold(
              body: batches.when(
                data: (list) => list.isEmpty
                    ? const Center(child: Text('No batches yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final b = list[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(
                                b.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${b.programName} · Term ${b.currentTerm}',
                              ),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await ref
                                        .read(adminServiceProvider)
                                        .promoteBatch(b.id);
                                    ref.invalidate(adminBatchesProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Batch promoted'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  minimumSize: const Size(80, 32),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                child: const Text('Promote'),
                              ),
                            ),
                          );
                        },
                      ),
                loading: () => const LoadingWidget(),
                error: (e, _) => AppErrorWidget(message: e.toString()),
              ),
              floatingActionButton: FloatingActionButton(
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _showAddBatch(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProgram(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedType = 'semester';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Program'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Program Name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Type: '),
                  DropdownButton<String>(
                    value: selectedType,
                    items: const [
                      DropdownMenuItem(
                        value: 'semester',
                        child: Text('Semester'),
                      ),
                      DropdownMenuItem(value: 'year', child: Text('Year')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedType = val);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                try {
                  await ref
                      .read(adminServiceProvider)
                      .createProgram(
                        name: nameController.text,
                        type: selectedType,
                      );
                  ref.invalidate(adminProgramsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Program created')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBatch(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final yearController = TextEditingController();
    final programIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Batch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: programIdController,
              decoration: const InputDecoration(labelText: 'Program ID'),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Batch Name'),
            ),
            TextField(
              controller: yearController,
              decoration: const InputDecoration(labelText: 'Intake Year'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(adminServiceProvider)
                    .createBatch(
                      programId: programIdController.text,
                      name: nameController.text,
                      intakeYear: int.tryParse(yearController.text) ?? 2024,
                    );
                ref.invalidate(adminBatchesProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Batch created')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
