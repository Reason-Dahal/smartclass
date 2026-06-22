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
      required: [true, 'Total terms is required'],
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

programSchema.pre('save', function (next) {
  if (!this.isModified('type')) return next();
  this.totalTerms = this.type === 'semester' ? 8 : 4;
  next();
});

const Program = mongoose.model('Program', programSchema);

module.exports = Program;