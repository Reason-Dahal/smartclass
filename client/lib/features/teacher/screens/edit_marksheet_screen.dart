import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../data/teacher_service.dart';
import '../models/teacher_models.dart';
import '../providers/teacher_providers.dart';

class EditMarksheetScreen extends ConsumerStatefulWidget {
  final TeacherCourseModel course;
  const EditMarksheetScreen({super.key, required this.course});

  @override
  ConsumerState<EditMarksheetScreen> createState() =>
      _EditMarksheetScreenState();
}

class _EditMarksheetScreenState extends ConsumerState<EditMarksheetScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _marksheets = [];
  List<int> _terms = [];
  int _selectedTerm = 1;
  String? _error;

  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _totalControllers = {};
  final Map<String, TextEditingController> _evalControllers = {};

  @override
  void initState() {
    super.initState();
    _loadMarksheets();
  }

  Future<void> _loadMarksheets() async {
    try {
      final service = ref.read(teacherServiceProvider);
      final marksheets = await service.getMarksheetsByCourse(widget.course.id);
      final terms = marksheets.map((m) => m['term'] as int).toSet().toList()
        ..sort();

      setState(() {
        _marksheets = marksheets;
        _terms = terms.isEmpty ? [1] : terms;
        _selectedTerm = terms.isEmpty ? 1 : terms.first;
        _isLoading = false;
      });

      _buildControllers();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _buildControllers() {
    // Clear old controllers
    for (final c in _marksControllers.values) c.dispose();
    for (final c in _totalControllers.values) c.dispose();
    for (final c in _evalControllers.values) c.dispose();
    _marksControllers.clear();
    _totalControllers.clear();
    _evalControllers.clear();

    final termMarksheets = _marksheets
        .where((m) => m['term'] == _selectedTerm)
        .toList();

    for (final m in termMarksheets) {
      final id = m['_id']?.toString() ?? '';
      _marksControllers[id] = TextEditingController(
        text: m['internalExamMarks']?.toString() ?? '',
      );
      _totalControllers[id] = TextEditingController(
        text: m['internalExamTotalMarks']?.toString() ?? '',
      );
      _evalControllers[id] = TextEditingController(
        text: m['teacherEvaluationScore']?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _marksControllers.values) c.dispose();
    for (final c in _totalControllers.values) c.dispose();
    for (final c in _evalControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final service = ref.read(teacherServiceProvider);
    final termMarksheets = _marksheets
        .where((m) => m['term'] == _selectedTerm)
        .toList();

    try {
      for (final m in termMarksheets) {
        final id = m['_id']?.toString() ?? '';
        final studentData = m['studentId'] is Map
            ? m['studentId'] as Map
            : <String, dynamic>{};
        final studentId = studentData['_id']?.toString() ?? '';

        await service.uploadMarksheet(
          widget.course.id,
          studentId: studentId,
          term: _selectedTerm,
          internalExamMarks:
              double.tryParse(_marksControllers[id]?.text ?? '0') ?? 0,
          internalExamTotalMarks:
              double.tryParse(_totalControllers[id]?.text ?? '0') ?? 0,
          teacherEvaluationScore:
              double.tryParse(_evalControllers[id]?.text ?? '0') ?? 0,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marksheets updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final termMarksheets = _marksheets
        .where((m) => m['term'] == _selectedTerm)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Marksheet — ${widget.course.subjectName}',
          style: const TextStyle(fontSize: 15),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _marksheets.isEmpty
          ? const Center(child: Text('No marksheets found'))
          : Column(
              children: [
                // Term selector
                if (_terms.length > 1)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<int>(
                      value: _selectedTerm,
                      decoration: const InputDecoration(
                        labelText: 'Term',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: _terms
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text('Term $t'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedTerm = val);
                          _buildControllers();
                        }
                      },
                    ),
                  ),

                // Table header
                Container(
                  color: AppColors.infoLight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Student',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Marks',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Total',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Eval',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Student rows
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: termMarksheets.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final m = termMarksheets[index];
                      final id = m['_id']?.toString() ?? '';
                      final studentData = m['studentId'] is Map
                          ? m['studentId'] as Map
                          : <String, dynamic>{};
                      final userData = studentData['userId'] is Map
                          ? studentData['userId'] as Map
                          : <String, dynamic>{};
                      final name = userData['name'] ?? 'Student ${index + 1}';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _marksControllers[id],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextField(
                                controller: _totalControllers[id],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextField(
                                controller: _evalControllers[id],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
