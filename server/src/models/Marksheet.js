const mongoose = require('mongoose');

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

marksheetSchema.index({ studentId: 1, courseId: 1, term: 1 }, { unique: true });

const Marksheet = mongoose.model('Marksheet', marksheetSchema);

module.exports = Marksheet;