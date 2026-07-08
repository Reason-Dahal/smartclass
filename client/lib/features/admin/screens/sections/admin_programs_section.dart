import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/admin_models.dart';
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
            // ── PROGRAMS TAB ──────────────────────────────────────
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
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
                                  IconButton(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      size: 20,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: () =>
                                        _showProgramOptions(context, ref, p),
                                  ),
                                ],
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

            // ── BATCHES TAB ───────────────────────────────────────
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
                                '${b.programName} · Term ${b.currentTerm} · ${b.intakeYear}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Active/Inactive badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: b.isActive
                                          ? AppColors.successLight
                                          : AppColors.dangerLight,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      b.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        color: b.isActive
                                            ? AppColors.success
                                            : AppColors.danger,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _promoteBatch(context, ref, b),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      minimumSize: const Size(70, 30),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                    child: const Text('Promote'),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      size: 20,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: () =>
                                        _showBatchOptions(context, ref, b),
                                  ),
                                ],
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

  // ── PROGRAM OPTIONS ─────────────────────────────────────────────
  void _showProgramOptions(
    BuildContext context,
    WidgetRef ref,
    ProgramModel p,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${p.type} · ${p.totalTerms} terms',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Edit Name'),
              onTap: () {
                Navigator.pop(context);
                _showEditProgram(context, ref, p);
              },
            ),
            // Show Deactivate OR Reactivate based on current status
            if (p.isActive)
              ListTile(
                leading: const Icon(
                  Icons.pause_circle_outline,
                  color: AppColors.textMuted,
                ),
                title: const Text('Deactivate'),
                subtitle: const Text(
                  'Hidden from new course creation',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _deactivateProgram(context, ref, p);
                },
              )
            else
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                title: const Text('Reactivate'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ref
                        .read(adminServiceProvider)
                        .reactivateProgram(p.id);
                    ref.invalidate(adminProgramsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Program reactivated'),
                          backgroundColor: AppColors.success,
                        ),
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
              ),
          ],
        ),
      ),
    );
  }

  void _showEditProgram(BuildContext context, WidgetRef ref, ProgramModel p) {
    final nameController = TextEditingController(text: p.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Program'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Program Name',
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              try {
                await ref
                    .read(adminServiceProvider)
                    .editProgram(
                      programId: p.id,
                      name: nameController.text.trim(),
                    );
                ref.invalidate(adminProgramsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Program updated'),
                      backgroundColor: AppColors.success,
                    ),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivateProgram(
    BuildContext context,
    WidgetRef ref,
    ProgramModel p,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Program'),
        content: Text(
          'Deactivate ${p.name}? Existing courses and batches are unaffected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Deactivate',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(adminServiceProvider).deactivateProgram(p.id);
      ref.invalidate(adminProgramsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Program deactivated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // ── BATCH OPTIONS ───────────────────────────────────────────────
  void _showBatchOptions(BuildContext context, WidgetRef ref, BatchModel b) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              b.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${b.programName} · Intake ${b.intakeYear}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Edit Batch'),
              onTap: () {
                Navigator.pop(context);
                _showEditBatch(context, ref, b);
              },
            ),
            if (b.isActive)
              ListTile(
                leading: const Icon(
                  Icons.pause_circle_outline,
                  color: AppColors.textMuted,
                ),
                title: const Text('Deactivate'),
                subtitle: const Text(
                  'Hidden from student creation',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _deactivateBatch(context, ref, b);
                },
              )
            else
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                title: const Text('Reactivate'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ref.read(adminServiceProvider).reactivateBatch(b.id);
                    ref.invalidate(adminBatchesProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Batch reactivated'),
                          backgroundColor: AppColors.success,
                        ),
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
              ),
          ],
        ),
      ),
    );
  }

  void _showEditBatch(BuildContext context, WidgetRef ref, BatchModel b) {
    final nameController = TextEditingController(text: b.name);
    final yearController = TextEditingController(text: b.intakeYear.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Batch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Batch Name',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yearController,
              decoration: const InputDecoration(
                labelText: 'Intake Year',
                isDense: true,
              ),
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
                    .editBatch(
                      batchId: b.id,
                      name: nameController.text.trim(),
                      intakeYear: int.tryParse(yearController.text),
                    );
                ref.invalidate(adminBatchesProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Batch updated'),
                      backgroundColor: AppColors.success,
                    ),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivateBatch(
    BuildContext context,
    WidgetRef ref,
    BatchModel b,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Batch'),
        content: Text(
          'Deactivate ${b.name}? Students in this batch are unaffected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Deactivate',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(adminServiceProvider).deactivateBatch(b.id);
      ref.invalidate(adminBatchesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batch deactivated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _promoteBatch(
    BuildContext context,
    WidgetRef ref,
    BatchModel b,
  ) async {
    try {
      await ref.read(adminServiceProvider).promoteBatch(b.id);
      ref.invalidate(adminBatchesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batch promoted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // ── ADD PROGRAM ─────────────────────────────────────────────────
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
                decoration: const InputDecoration(
                  labelText: 'Program Name',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'semester',
                    child: Text('Semester (8 terms)'),
                  ),
                  DropdownMenuItem(
                    value: 'year',
                    child: Text('Year (4 years)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedType = val);
                },
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
                        name: nameController.text.trim(),
                        type: selectedType,
                      );
                  ref.invalidate(adminProgramsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Program created'),
                        backgroundColor: AppColors.success,
                      ),
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

  // ── ADD BATCH ───────────────────────────────────────────────────
  void _showAddBatch(BuildContext context, WidgetRef ref) async {
    final service = ref.read(adminServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final programs = await service.getPrograms();
      if (context.mounted) Navigator.pop(context);

      if (programs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create a program first')),
          );
        }
        return;
      }

      String? selectedProgramId = programs.first.id;
      final nameController = TextEditingController();
      final yearController = TextEditingController(
        text: DateTime.now().year.toString(),
      );

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: const Text('Add Batch'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Program dropdown — replaces raw ID field
                  DropdownButtonFormField<String>(
                    value: selectedProgramId,
                    decoration: const InputDecoration(
                      labelText: 'Program',
                      isDense: true,
                    ),
                    isExpanded: true,
                    items: programs
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              '${p.name} (${p.type})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => selectedProgramId = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Batch Name',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: yearController,
                    decoration: const InputDecoration(
                      labelText: 'Intake Year',
                      isDense: true,
                    ),
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
                    if (nameController.text.isEmpty ||
                        selectedProgramId == null)
                      return;
                    try {
                      await service.createBatch(
                        programId: selectedProgramId!,
                        name: nameController.text.trim(),
                        intakeYear:
                            int.tryParse(yearController.text) ??
                            DateTime.now().year,
                      );
                      ref.invalidate(adminBatchesProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Batch created'),
                            backgroundColor: AppColors.success,
                          ),
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
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
