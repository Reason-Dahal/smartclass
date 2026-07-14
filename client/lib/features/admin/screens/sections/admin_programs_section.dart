import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_providers.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class AdminProgramsSection extends ConsumerStatefulWidget {
  const AdminProgramsSection({super.key});

  @override
  ConsumerState<AdminProgramsSection> createState() =>
      _AdminProgramsSectionState();
}

class _AdminProgramsSectionState extends ConsumerState<AdminProgramsSection> {
  // Tracks which batch IDs currently have a promotion in flight —
  // prevents double-tapping Promote on the same batch while it saves.
  final Set<String> _promotingBatchIds = {};

  @override
  Widget build(BuildContext context) {
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
            //PROGRAMS TAB
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

            // BATCHES TAB
            Scaffold(
              body: batches.when(
                data: (list) => list.isEmpty
                    ? const Center(child: Text('No batches yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final b = list[index];
                          final isPromoting = _promotingBatchIds.contains(b.id);
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
                                  // Fixed-size box so the row doesn't jump
                                  // when swapping between button and spinner
                                  SizedBox(
                                    width: 70,
                                    height: 30,
                                    child: isPromoting
                                        ? const Center(
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : ElevatedButton(
                                            onPressed: () =>
                                                _promoteBatch(context, ref, b),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              minimumSize: const Size(70, 30),
                                              padding: EdgeInsets.zero,
                                              textStyle: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            child: const Text('Promote'),
                                          ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      size: 20,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: isPromoting
                                        ? null
                                        : () => _showBatchOptions(
                                            context,
                                            ref,
                                            b,
                                          ),
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

  // PROGRAM OPTIONS
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
    bool isSubmitting = false;
    bool showNameError = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit Program'),
          content: TextField(
            controller: nameController,
            enabled: !isSubmitting,
            decoration: InputDecoration(
              labelText: 'Program Name',
              isDense: true,
              errorText: showNameError ? 'Name cannot be empty' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        setState(() => showNameError = true);
                        return;
                      }
                      setState(() => isSubmitting = true);
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
                        setState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
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

  // BATCH OPTIONS
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
    bool isSubmitting = false;
    bool showNameError = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit Batch'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                enabled: !isSubmitting,
                decoration: InputDecoration(
                  labelText: 'Batch Name',
                  isDense: true,
                  errorText: showNameError ? 'Name cannot be empty' : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearController,
                enabled: !isSubmitting,
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
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        setState(() => showNameError = true);
                        return;
                      }
                      setState(() => isSubmitting = true);
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
                        setState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
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
    // Batch promotion moves every student in this batch to the next term
    // and auto-enrolls them in that term's compulsory courses — a real
    // consequential action, so we confirm before running it, same as
    // Deactivate.
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Promote Batch'),
        content: Text(
          'Promote ${b.name} from Term ${b.currentTerm} to Term '
          '${b.currentTerm + 1}? All students in this batch will be '
          'auto-enrolled in the next term\'s compulsory courses.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Promote'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _promotingBatchIds.add(b.id));
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
    } finally {
      if (mounted) {
        setState(() => _promotingBatchIds.remove(b.id));
      }
    }
  }

  //ADD PROGRAM
  void _showAddProgram(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedType = 'semester';
    bool isSubmitting = false;
    bool showNameError = false;

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
                enabled: !isSubmitting,
                decoration: InputDecoration(
                  labelText: 'Program Name',
                  isDense: true,
                  errorText: showNameError ? 'Name cannot be empty' : null,
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
                onChanged: isSubmitting
                    ? null
                    : (val) {
                        if (val != null) setState(() => selectedType = val);
                      },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        setState(() => showNameError = true);
                        return;
                      }
                      setState(() => isSubmitting = true);
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
                        setState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // ADD BATCH
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
      bool isSubmitting = false;
      bool showNameError = false;

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: const Text('Add Batch'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    onChanged: isSubmitting
                        ? null
                        : (val) => setState(() => selectedProgramId = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    enabled: !isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'Batch Name',
                      isDense: true,
                      errorText: showNameError ? 'Name cannot be empty' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: yearController,
                    enabled: !isSubmitting,
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
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty) {
                            setState(() => showNameError = true);
                            return;
                          }
                          if (selectedProgramId == null) return;

                          setState(() => isSubmitting = true);
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
                            setState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create'),
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
