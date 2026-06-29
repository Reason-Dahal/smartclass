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
    usageCount: {
      type: Number,
      default: 0,
      min: 0,
    },
    lastUsedAt: {
      type: Date,
      default: null,
    },
  },

  
  {
    timestamps: true,
  }
);

courseSchema.index({ programId: 1, term: 1, subjectName: 1 }, { unique: true });

courseSchema.statics.incrementUsage = async function (courseId) {
  try {
    await this.findByIdAndUpdate(courseId, {
      $inc: { usageCount: 1 },
      $set: { lastUsedAt: new Date() },
    });
  } catch (err) {
    // Fire and forget — usage tracking never blocks the main operation
    console.error('Usage increment failed:', err.message);
  }
};



const Course = mongoose.model('Course', courseSchema);

module.exports = Course;