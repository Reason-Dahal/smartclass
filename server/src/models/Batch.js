const mongoose = require('mongoose');

const batchSchema = new mongoose.Schema(
  {
    programId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Program',
      required: true,
    },
    name: {
      type: String,
      required: [true, 'Batch name is required'],
      trim: true,
    },
    intakeYear: {
      type: Number,
      required: [true, 'Intake year is required'],
    },
    currentTerm: {
      type: Number,
      default: 1,
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

batchSchema.index({ programId: 1, intakeYear: 1 }, { unique: true });

const Batch = mongoose.model('Batch', batchSchema);

module.exports = Batch;