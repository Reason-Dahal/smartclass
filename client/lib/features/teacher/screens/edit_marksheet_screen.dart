import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../models/teacher_models.dart';
import '../providers/teacher_providers.dart';

class EditMarksheetScreen extends ConsumerStatefulWidget {
  final TeacherCourseModel course;
  final String mode; // 'create' or 'edit'

  const EditMarksheetScreen({
    super.key,
    required this.course,
    this.mode = 'edit',
  });

  @override
  ConsumerState<EditMarksheetScreen> createState() =>
      _EditMarksheetScreenState();
}

class _EditMarksheetScreenState extends ConsumerState<EditMarksheetScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // For edit mode — existing marksheet records
  List<Map<String, dynamic>> _marksheets = [];

  // For create mode — enrolled students
  List<Map<String, dynamic>> _students = [];

  List<int> _terms = [];
  int _selectedTerm = 1;

  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _totalControllers = {};
  final Map<String, TextEditingController> _evalControllers = {};

  // Tracks student IDs for create mode
  final List<String> _studentIds = [];
  final List<String> _studentNames = [];

  bool get _isCreateMode => widget.mode == 'create';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final service = ref.read(teacherServiceProvider);

      if (_isCreateMode) {
        // Create mode — load enrolled students
        final students = await service.getCourseStudents(widget.course.id);
        setState(() {
          _students = students;
          _terms = [widget.course.term];
          _selectedTerm = widget.course.term;
          _isLoading = false;
        });
        _buildControllersFromStudents();
      } else {
        // Edit mode — load existing marksheets
        final marksheets = await service.getMarksheetsByCourse(
          widget.course.id,
        );

        if (marksheets.isEmpty) {
          // No marksheets yet — switch to create mode automatically
          final students = await service.getCourseStudents(widget.course.id);
          setState(() {
            _students = students;
            _terms = [widget.course.term];
            _selectedTerm = widget.course.term;
            _isLoading = false;
          });
          _buildControllersFromStudents();
          return;
        }

        final terms = marksheets.map((m) => m['term'] as int).toSet().toList()
          ..sort();

        setState(() {
          _marksheets = marksheets;
          _terms = terms;
          _selectedTerm = terms.first;
          _isLoading = false;
        });
        _buildControllersFromMarksheets();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Build controllers from enrolled students (empty fields)
  void _buildControllersFromStudents() {
    _disposeControllers();
    _studentIds.clear();
    _studentNames.clear();

    for (final student in _students) {
      final id = student['studentId']?.toString() ?? '';
      final name = student['name']?.toString() ?? 'Student';

      _studentIds.add(id);
      _studentNames.add(name);
      _marksControllers[id] = TextEditingController();
      _totalControllers[id] = TextEditingController();
      _evalControllers[id] = TextEditingController();
    }
    setState(() {});
  }

  // Build controllers from existing marksheets (pre-filled)
  void _buildControllersFromMarksheets() {
    _disposeControllers();
    _studentIds.clear();
    _studentNames.clear();

    final termMarksheets = _marksheets
        .where((m) => m['term'] == _selectedTerm)
        .toList();

    for (final m in termMarksheets) {
      final id = m['_id']?.toString() ?? '';
      final studentData = m['studentId'] is Map
          ? m['studentId'] as Map
          : <String, dynamic>{};
      final userData = studentData['userId'] is Map
          ? studentData['userId'] as Map
          : <String, dynamic>{};

      _studentIds.add(studentData['_id']?.toString() ?? '');
      _studentNames.add(userData['name'] ?? 'Student');

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
    setState(() {});
  }

  void _disposeControllers() {
    for (final c in _marksControllers.values) c.dispose();
    for (final c in _totalControllers.values) c.dispose();
    for (final c in _evalControllers.values) c.dispose();
    _marksControllers.clear();
    _totalControllers.clear();
    _evalControllers.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final service = ref.read(teacherServiceProvider);

    try {
      // Build the marksheets payload — one entry per student, regardless of mode.
      final List<Map<String, dynamic>> payload;

      if (_isCreateMode || _marksheets.isEmpty) {
        // Create mode — controllers keyed by student ID directly
        payload = _studentIds.map((studentId) {
          return {
            'studentId': studentId,
            'internalExamMarks':
                double.tryParse(_marksControllers[studentId]?.text ?? '0') ?? 0,
            'internalExamTotalMarks':
                double.tryParse(_totalControllers[studentId]?.text ?? '0') ?? 0,
            'teacherEvaluationScore':
                double.tryParse(_evalControllers[studentId]?.text ?? '0') ?? 0,
          };
        }).toList();
      } else {
        // Edit mode — controllers keyed by marksheet ID
        final termMarksheets = _marksheets
            .where((m) => m['term'] == _selectedTerm)
            .toList();

        payload = termMarksheets.map((m) {
          final id = m['_id']?.toString() ?? '';
          final studentData = m['studentId'] is Map
              ? m['studentId'] as Map
              : <String, dynamic>{};
          final studentId = studentData['_id']?.toString() ?? '';

          return {
            'studentId': studentId,
            'internalExamMarks':
                double.tryParse(_marksControllers[id]?.text ?? '0') ?? 0,
            'internalExamTotalMarks':
                double.tryParse(_totalControllers[id]?.text ?? '0') ?? 0,
            'teacherEvaluationScore':
                double.tryParse(_evalControllers[id]?.text ?? '0') ?? 0,
          };
        }).toList();
      }

      // Single request — backend wraps this in a transaction.
      // Either every student in this batch saves, or none do.
      await service.bulkUploadMarksheets(
        widget.course.id,
        term: _selectedTerm,
        marksheets: payload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marksheets saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed — nothing was changed. ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Keys for create mode — student IDs are used directly
  // Keys for edit mode — marksheet IDs are used
  List<String> get _keys {
    if (_isCreateMode || _marksheets.isEmpty) return _studentIds;
    return _marksheets
        .where((m) => m['term'] == _selectedTerm)
        .map((m) => m['_id']?.toString() ?? '')
        .toList();
  }

  List<String> get _names {
    if (_isCreateMode || _marksheets.isEmpty) return _studentNames;
    return _marksheets.where((m) => m['term'] == _selectedTerm).map((m) {
      final studentData = m['studentId'] is Map
          ? m['studentId'] as Map
          : <String, dynamic>{};
      final userData = studentData['userId'] is Map
          ? studentData['userId'] as Map
          : <String, dynamic>{};
      return userData['name']?.toString() ?? 'Student';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final keys = _keys;
    final names = _names;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_isCreateMode ? 'Enter' : 'Edit'} Marksheet — ${widget.course.subjectName}',
          style: const TextStyle(fontSize: 15),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Save All',
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
          : keys.isEmpty
          ? const Center(child: Text('No students enrolled in this course'))
          : Column(
              children: [
                // Term selector — only in edit mode
                if (!_isCreateMode && _terms.length > 1)
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
                          _buildControllersFromMarksheets();
                        }
                      },
                    ),
                  ),

                // Term display — in create mode
                if (_isCreateMode)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: AppColors.infoLight,
                    child: Text(
                      'Term $_selectedTerm — ${widget.course.subjectName}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // Table header
                Container(
                  color: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
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
                            color: Colors.white,
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
                            color: Colors.white,
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
                            color: Colors.white,
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
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Student rows
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: keys.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final key = keys[index];
                      final name = index < names.length
                          ? names[index]
                          : 'Student ${index + 1}';

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
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
                                controller: _marksControllers[key],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                  hintText: '0',
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextField(
                                controller: _totalControllers[key],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                  hintText: '0',
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextField(
                                controller: _evalControllers[key],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                  hintText: '0',
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
