const mongoose = require('mongoose');

const finalResultSchema = new mongoose.Schema(
  {
    programId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Program',
      required: [true, 'Program is required'],
    },
    term: {
      type: Number,
      required: [true, 'Term is required'],
      min: 1,
    },
    fileUrl: {
      type: String,
      required: [true, 'Result file URL is required'],
    },
    fileType: {
      type: String,
      enum: ['pdf', 'docx'],
      required: [true, 'File type is required'],
    },
    publishedDate: {
      type: Date,
      default: Date.now,
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

// One result file per program per term
// Upsert on this index allows admin to overwrite a result for the same term
finalResultSchema.index({ programId: 1, term: 1 }, { unique: true });

const FinalResult = mongoose.model('FinalResult', finalResultSchema);

module.exports = FinalResult;