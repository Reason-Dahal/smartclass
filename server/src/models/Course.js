const mongoose = require('mongoose');

const courseSchema = new mongoose.Schema(
  {
    programId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Program',
      required: true,
    },
    teacherId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Teacher',
      required: true,
    },
    subjectName: {
      type: String,
      required: [true, 'Subject name is required'],
      trim: true,
    },
    term: {
      type: Number,
      required: [true, 'Term is required'],
    },
    isElective: {
      type: Boolean,
      default: false,
    },
    evaluationEnabled: {
      type: Boolean,
      default: false,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

courseSchema.index({ programId: 1, term: 1, subjectName: 1 }, { unique: true });

const Course = mongoose.model('Course', courseSchema);

module.exports = Course;