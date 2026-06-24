import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/app_router.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/admin_service.dart';
import '../models/admin_models.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';
import 'dart:convert';

// ─── PROVIDERS ───────────────────────────────────────────────────

final adminServiceProvider = Provider((ref) => AdminService());

final adminTeachersProvider = FutureProvider<List<AdminUserModel>>((ref) async {
  return ref.read(adminServiceProvider).getTeachers();
});

final adminStudentsProvider = FutureProvider<List<AdminUserModel>>((ref) async {
  return ref.read(adminServiceProvider).getStudents();
});

final adminProgramsProvider = FutureProvider<List<ProgramModel>>((ref) async {
  return ref.read(adminServiceProvider).getPrograms();
});

final adminBatchesProvider = FutureProvider<List<BatchModel>>((ref) async {
  return ref.read(adminServiceProvider).getAllBatches();
});

final adminReportsProvider = FutureProvider<SystemReportModel>((ref) async {
  return ref.read(adminServiceProvider).getReports();
});

// ─── DASHBOARD ───────────────────────────────────────────────────

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _userName = '';
  int _currentSection = 0;

  // 0 = home, 1 = teachers, 2 = students, 3 = programs, 4 = reports

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final userJson = await SecureStorage.getUser();
    if (userJson != null && mounted) {
      final user = jsonDecode(userJson);
      setState(() => _userName = user['name'] ?? '');
    }
  }

  Future<void> _logout() async {
    await SecureStorage.clearAll();
    if (mounted) context.go(AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_sectionTitle()),
        leading: _currentSection != 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentSection = 0),
              )
            : null,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _buildSection(),
    );
  }

  String _sectionTitle() {
    switch (_currentSection) {
      case 1:
        return 'Teachers';
      case 2:
        return 'Students';
      case 3:
        return 'Programs & Batches';
      case 4:
        return 'Reports';
      default:
        return AppConstants.appName;
    }
  }

  Widget _buildSection() {
    switch (_currentSection) {
      case 1:
        return _TeachersSection();
      case 2:
        return _StudentsSection();
      case 3:
        return _ProgramsSection();
      case 4:
        return _ReportsSection();
      default:
        return _HomeSection(
          userName: _userName,
          onNavigate: (index) => setState(() => _currentSection = index),
        );
    }
  }
}

// ─── HOME SECTION ────────────────────────────────────────────────

class _HomeSection extends ConsumerWidget {
  final String userName;
  final Function(int) onNavigate;

  const _HomeSection({required this.userName, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(adminReportsProvider);
    final teachers = ref.watch(adminTeachersProvider);
    final students = ref.watch(adminStudentsProvider);
    final programs = ref.watch(adminProgramsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminReportsProvider);
        ref.invalidate(adminTeachersProvider);
        ref.invalidate(adminStudentsProvider);
        ref.invalidate(adminProgramsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            Text(
              'Welcome back',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                _StatBadge(
                  label: 'Students',
                  value:
                      students.whenOrNull(data: (l) => '${l.length}') ?? '...',
                ),
                const SizedBox(width: 10),
                _StatBadge(
                  label: 'Teachers',
                  value:
                      teachers.whenOrNull(data: (l) => '${l.length}') ?? '...',
                ),
                const SizedBox(width: 10),
                _StatBadge(
                  label: 'Programs',
                  value:
                      programs.whenOrNull(data: (l) => '${l.length}') ?? '...',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick actions grid
            const Text(
              'Quick actions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _ActionCard(
                  icon: Icons.person_add_outlined,
                  label: 'Add Teacher',
                  color: AppColors.primary,
                  onTap: () => onNavigate(1),
                ),
                _ActionCard(
                  icon: Icons.school_outlined,
                  label: 'Add Student',
                  color: AppColors.info,
                  onTap: () => onNavigate(2),
                ),
                _ActionCard(
                  icon: Icons.account_balance_outlined,
                  label: 'Programs',
                  color: AppColors.success,
                  onTap: () => onNavigate(3),
                ),
                _ActionCard(
                  icon: Icons.bar_chart_outlined,
                  label: 'Reports',
                  color: AppColors.warning,
                  onTap: () => onNavigate(4),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Attendance overview
            const Text(
              'System overview',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            reports.when(
              data: (report) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _ReportRow(
                        label: 'Overall attendance',
                        value: report.overallAttendanceRate,
                      ),
                      const Divider(),
                      _ReportRow(
                        label: 'Total assignments',
                        value: '${report.totalAssignments}',
                      ),
                      const Divider(),
                      _ReportRow(
                        label: 'Submission rate',
                        value: report.submissionRate,
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const LoadingWidget(),
              error: (e, _) => AppErrorWidget(message: e.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TEACHERS SECTION ────────────────────────────────────────────

class _TeachersSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachers = ref.watch(adminTeachersProvider);

    return Scaffold(
      body: teachers.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('No teachers yet'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminTeachersProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) => _UserCard(user: list[index]),
                ),
              ),
        loading: () => const LoadingWidget(message: 'Loading teachers...'),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminTeachersProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddTeacher(context, ref),
      ),
    );
  }

  void _showAddTeacher(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final deptController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Teacher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: deptController,
              decoration: const InputDecoration(labelText: 'Department'),
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
                  emailController.text.isEmpty ||
                  deptController.text.isEmpty)
                return;
              try {
                final service = ref.read(adminServiceProvider);
                await service.createTeacher(
                  name: nameController.text,
                  email: emailController.text,
                  department: deptController.text,
                );
                ref.invalidate(adminTeachersProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Teacher created successfully'),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ─── STUDENTS SECTION ────────────────────────────────────────────

class _StudentsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(adminStudentsProvider);

    return Scaffold(
      body: students.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('No students yet'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminStudentsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) => _UserCard(user: list[index]),
                ),
              ),
        loading: () => const LoadingWidget(message: 'Loading students...'),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminStudentsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddStudent(context, ref),
      ),
    );
  }

  void _showAddStudent(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final rollController = TextEditingController();
    final programIdController = TextEditingController();
    final batchIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: rollController,
                decoration: const InputDecoration(labelText: 'Roll Number'),
              ),
              TextField(
                controller: programIdController,
                decoration: const InputDecoration(labelText: 'Program ID'),
              ),
              TextField(
                controller: batchIdController,
                decoration: const InputDecoration(labelText: 'Batch ID'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final service = ref.read(adminServiceProvider);
                await service.createStudent(
                  name: nameController.text,
                  email: emailController.text,
                  rollNumber: rollController.text,
                  programId: programIdController.text,
                  batchId: batchIdController.text,
                );
                ref.invalidate(adminStudentsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student created successfully'),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ─── PROGRAMS SECTION ────────────────────────────────────────────

class _ProgramsSection extends ConsumerWidget {
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

// ─── REPORTS SECTION ─────────────────────────────────────────────

class _ReportsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(adminReportsProvider);

    return reports.when(
      data: (report) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminReportsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ReportCard(
              title: 'Overview',
              children: [
                _ReportRow(
                  label: 'Total students',
                  value: '${report.totalStudents}',
                ),
                _ReportRow(
                  label: 'Total teachers',
                  value: '${report.totalTeachers}',
                ),
                _ReportRow(
                  label: 'Total programs',
                  value: '${report.totalPrograms}',
                ),
                _ReportRow(
                  label: 'Total courses',
                  value: '${report.totalCourses}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ReportCard(
              title: 'Attendance',
              children: [
                _ReportRow(
                  label: 'Overall rate',
                  value: report.overallAttendanceRate,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ReportCard(
              title: 'Assignments',
              children: [
                _ReportRow(
                  label: 'Total assignments',
                  value: '${report.totalAssignments}',
                ),
                _ReportRow(
                  label: 'Total submissions',
                  value: '${report.totalSubmissions}',
                ),
                _ReportRow(
                  label: 'Submission rate',
                  value: report.submissionRate,
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => const LoadingWidget(message: 'Loading reports...'),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(adminReportsProvider),
      ),
    );
  }
}

// ─── REUSABLE WIDGETS ─────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;

  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUserModel user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.infoLight,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(user.email),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: user.status == 'active'
                ? AppColors.successLight
                : AppColors.dangerLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user.status,
            style: TextStyle(
              color: user.status == 'active'
                  ? AppColors.success
                  : AppColors.danger,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ReportCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReportRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
