const mongoose = require('mongoose');

const programSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Program name is required'],
      unique: true,
      trim: true,
    },
    type: {
      type: String,
      enum: ['semester', 'year'],
      required: [true, 'Program type is required'],
    },
    totalTerms: {
      type: Number,
      default: 0,
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

programSchema.pre('save', function () {
  if (!this.isModified('type')) return;
  this.totalTerms = this.type === 'semester' ? 8 : 4;
});

const Program = mongoose.model('Program', programSchema);

module.exports = Program;