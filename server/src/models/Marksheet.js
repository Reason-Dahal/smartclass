const mongoose = require('mongoose');

const EXAM_TYPES = ['first_terminal', 'mid_term', 'pre_board'];

const marksheetSchema = new mongoose.Schema(
  {
    studentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Student',
      required: true,
    },
    courseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Course',
      required: true,
    },
    term: {
      type: Number,
      required: true,
    },
    examType: {
      type: String,
      enum: EXAM_TYPES,
      required: true,
    },
    internalExamMarks: {
      type: Number,
      required: true,
      min: 0,
    },
    internalExamTotalMarks: {
      type: Number,
      required: true,
      min: 1,
    },
    teacherEvaluationScore: {
      type: Number,
      required: true,
      min: 0,
      max: 100,
    },
    uploadedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// One marksheet per student, per course, per term, per exam type —
// First Terminal, Mid Term, and Pre-Board are now independent records.
marksheetSchema.index(
  { studentId: 1, courseId: 1, term: 1, examType: 1 },
  { unique: true }
);

const Marksheet = mongoose.model('Marksheet', marksheetSchema);
Marksheet.EXAM_TYPES = EXAM_TYPES;

module.exports = Marksheet;