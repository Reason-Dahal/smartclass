const mongoose = require('mongoose');

const finalResultSchema = new mongoose.Schema(
  {
    studentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Student',
      required: true,
    },
    term: {
      type: Number,
      required: true,
    },
    overallStatus: {
      type: String,
      enum: ['pass', 'fail'],
      required: true,
    },
    courseResults: [
      {
        courseId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'Course',
          required: true,
        },
        status: {
          type: String,
          enum: ['pass', 'fail'],
          required: true,
        },
      },
    ],
    publishedDate: {
      type: Date,
      required: true,
    },
    enteredBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

finalResultSchema.index({ studentId: 1, term: 1 }, { unique: true });

const FinalResult = mongoose.model('FinalResult', finalResultSchema);

module.exports = FinalResult;