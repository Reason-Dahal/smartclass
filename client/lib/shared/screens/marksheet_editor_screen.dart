import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

const Map<String, String> kExamTypeLabels = {
  'first_terminal': 'First Terminal',
  'mid_term': 'Mid Term',
  'pre_board': 'Pre-Board',
};

const List<String> kExamTypes = ['first_terminal', 'mid_term', 'pre_board'];

/// Shared marksheet entry/edit screen, used by both teacher (own courses
/// only) and admin (any course, override mode) via dependency injection —
/// the screen doesn't know or care which role is using it, it just calls
/// whatever functions it's given.
///
/// Always loads the full enrolled roster AND existing marksheets, then
/// merges them by studentId — so newly enrolled students always appear,
/// pre-filled with existing marks where available and empty otherwise.
///
/// Marks are entered per exam type (First Terminal / Mid Term / Pre-Board)
/// — the teacher/admin picks which exam they're entering marks for,
/// same as they pick the term.
class MarksheetEditorScreen extends StatefulWidget {
  final String courseId;
  final String subjectName;
  final int courseTerm;
  final String mode; // kept only for the AppBar title wording

  final Future<List<Map<String, dynamic>>> Function(String courseId)
  getCourseStudents;
  final Future<List<Map<String, dynamic>>> Function(String courseId)
  getMarksheetsByCourse;
  final Future<void> Function(
    String courseId, {
    required int term,
    required String examType,
    required List<Map<String, dynamic>> marksheets,
  })
  bulkUpload;

  const MarksheetEditorScreen({
    super.key,
    required this.courseId,
    required this.subjectName,
    required this.courseTerm,
    required this.getCourseStudents,
    required this.getMarksheetsByCourse,
    required this.bulkUpload,
    this.mode = 'edit',
  });

  @override
  State<MarksheetEditorScreen> createState() => _MarksheetEditorScreenState();
}

class _MarksheetEditorScreenState extends State<MarksheetEditorScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // Full enrolled roster — always the source of truth for who appears.
  List<Map<String, dynamic>> _roster = [];

  // All existing marksheets for this course, across whichever terms
  // and exam types exist.
  List<Map<String, dynamic>> _allMarksheets = [];

  List<int> _terms = [];
  int _selectedTerm = 1;

  // Exam type is always all three, fixed — teacher can enter marks for
  // any of them regardless of whether one already has data, so this
  // isn't derived from existing records like _terms is.
  String _selectedExamType = kExamTypes.first;

  // Every controller is keyed by studentId — consistently, regardless
  // of whether that student already has a marksheet or not.
  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _evalControllers = {};
  final TextEditingController _sharedTotalController = TextEditingController(
    text: '100',
  );

  // Ordered list of studentIds currently shown, and their display names —
  // rebuilt from the roster every time the selected term/examType changes.
  List<String> _studentIds = [];
  final Map<String, String> _studentNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      // Always fetch both — the roster tells us WHO should appear,
      // the marksheets tell us what marks (if any) they already have.
      final roster = await widget.getCourseStudents(widget.courseId);
      final marksheets = await widget.getMarksheetsByCourse(widget.courseId);

      final termsFromMarksheets = marksheets
          .map((m) => m['term'] as int)
          .toSet();
      final terms = ({widget.courseTerm, ...termsFromMarksheets}).toList()
        ..sort();

      setState(() {
        _roster = roster;
        _allMarksheets = marksheets;
        _terms = terms;
        _selectedTerm = terms.contains(widget.courseTerm)
            ? widget.courseTerm
            : terms.first;
        _isLoading = false;
      });

      _buildForSelection();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Rebuilds the visible list and controllers for whichever term AND
  // exam type is currently selected — always starting from the full
  // roster, then overlaying existing marks where they exist.
  void _buildForSelection() {
    _disposeControllers();
    _studentIds = [];
    _studentNames.clear();

    final matchingMarksheets = _allMarksheets
        .where(
          (m) =>
              m['term'] == _selectedTerm && m['examType'] == _selectedExamType,
        )
        .toList();

    // Map existing marksheet data by studentId for quick lookup.
    final marksByStudentId = <String, Map<String, dynamic>>{};
    for (final m in matchingMarksheets) {
      final studentData = m['studentId'] is Map
          ? m['studentId'] as Map
          : <String, dynamic>{};
      final studentId = studentData['_id']?.toString() ?? '';
      if (studentId.isNotEmpty) {
        marksByStudentId[studentId] = m;
      }
    }

    String? sharedTotalFromExisting;

    for (final student in _roster) {
      final studentId = student['studentId']?.toString() ?? '';
      final name = student['name']?.toString() ?? 'Student';
      if (studentId.isEmpty) continue;

      _studentIds.add(studentId);
      _studentNames[studentId] = name;

      final existingMark = marksByStudentId[studentId];

      _marksControllers[studentId] = TextEditingController(
        text: existingMark?['internalExamMarks']?.toString() ?? '',
      );
      _evalControllers[studentId] = TextEditingController(
        text: existingMark?['teacherEvaluationScore']?.toString() ?? '',
      );

      if (sharedTotalFromExisting == null &&
          existingMark?['internalExamTotalMarks'] != null) {
        sharedTotalFromExisting = existingMark!['internalExamTotalMarks']
            .toString();
      }
    }

    _sharedTotalController.text = sharedTotalFromExisting ?? '100';

    setState(() {});
  }

  void _disposeControllers() {
    for (final c in _marksControllers.values) {
      c.dispose();
    }
    for (final c in _evalControllers.values) {
      c.dispose();
    }
    _marksControllers.clear();
    _evalControllers.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    _sharedTotalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final sharedTotal = double.tryParse(_sharedTotalController.text) ?? 0;

    try {
      final payload = _studentIds.map((studentId) {
        return {
          'studentId': studentId,
          'internalExamMarks':
              double.tryParse(_marksControllers[studentId]?.text ?? '0') ?? 0,
          'internalExamTotalMarks': sharedTotal,
          'teacherEvaluationScore':
              double.tryParse(_evalControllers[studentId]?.text ?? '0') ?? 0,
        };
      }).toList();

      await widget.bulkUpload(
        widget.courseId,
        term: _selectedTerm,
        examType: _selectedExamType,
        marksheets: payload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${kExamTypeLabels[_selectedExamType]} marksheets saved successfully',
            ),
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

  @override
  Widget build(BuildContext context) {
    final hasAnyMarksheetForSelection = _allMarksheets.any(
      (m) => m['term'] == _selectedTerm && m['examType'] == _selectedExamType,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${hasAnyMarksheetForSelection ? 'Edit' : 'Enter'} Marksheet — ${widget.subjectName}',
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
          : _studentIds.isEmpty
          ? const Center(child: Text('No students enrolled in this course'))
          : Column(
              children: [
                // Exam type selector — always shown, since a teacher can
                // enter marks for any of the three exams regardless of
                // whether it already has data.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedExamType,
                    decoration: const InputDecoration(
                      labelText: 'Exam',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: kExamTypes
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(kExamTypeLabels[type]!),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedExamType = val);
                        _buildForSelection();
                      }
                    },
                  ),
                ),

                if (_terms.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedTerm,
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
                          _buildForSelection();
                        }
                      },
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Term $_selectedTerm — ${widget.subjectName}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _sharedTotalController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Total Marks (applies to all students)',
                      helperText:
                          'Set once — every student below shares this total',
                      isDense: true,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.rule, size: 18),
                    ),
                  ),
                ),

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

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _studentIds.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final studentId = _studentIds[index];
                      final name = _studentNames[studentId] ?? 'Student';

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
                                controller: _marksControllers[studentId],
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
                              child: Container(
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                child: Text(
                                  _sharedTotalController.text.isEmpty
                                      ? '0'
                                      : _sharedTotalController.text,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextField(
                                controller: _evalControllers[studentId],
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
