const mongoose = require('mongoose');

const evaluationConfigSchema = new mongoose.Schema(
  {
    attendanceWeight: {
      type: Number,
      required: true,
      default: 25,
      min: 0,
      max: 100,
    },
    internalExamWeight: {
      type: Number,
      required: true,
      default: 25,
      min: 0,
      max: 100,
    },
    assignmentWeight: {
      type: Number,
      required: true,
      default: 25,
      min: 0,
      max: 100,
    },
    teacherEvaluationWeight: {
      type: Number,
      required: true,
      default: 25,
      min: 0,
      max: 100,
    },
    updatedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
  },
  {
    timestamps: true,
  }
);

const EvaluationConfig = mongoose.model('EvaluationConfig', evaluationConfigSchema);

module.exports = EvaluationConfig;