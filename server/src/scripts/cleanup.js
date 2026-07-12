require('dotenv').config();
const connectDB = require('../config/db');

const User            = require('../models/User');
const Student          = require('../models/Student');
const Teacher           = require('../models/Teacher');
const Program            = require('../models/Program');
const Batch                = require('../models/Batch');
const Course                 = require('../models/Course');
const Enrollment               = require('../models/Enrollment');
const Attendance                   = require('../models/Attendance');
const Assignment                     = require('../models/Assignment');
const Submission                       = require('../models/Submission');
const Note                               = require('../models/Note');
const Marksheet                            = require('../models/Marksheet');
const FinalResult                            = require('../models/FinalResult');
const Notification                             = require('../models/Notification');
const EvaluationConfig                           = require('../models/EvaluationConfig');

const cleanup = async () => {
  await connectDB();

  console.log('Starting full cleanup — this will delete all data except the super admin account.\n');

  // Delete every non-admin User (teachers and students each have a linked User)
  const nonAdminResult = await User.deleteMany({ role: { $ne: 'admin' } });
  console.log(`Users (teacher/student) deleted: ${nonAdminResult.deletedCount}`);

  const collections = [
    { name: 'Student',           model: Student },
    { name: 'Teacher',            model: Teacher },
    { name: 'Program',             model: Program },
    { name: 'Batch',                 model: Batch },
    { name: 'Course',                  model: Course },
    { name: 'Enrollment',                model: Enrollment },
    { name: 'Attendance',                  model: Attendance },
    { name: 'Assignment',                    model: Assignment },
    { name: 'Submission',                      model: Submission },
    { name: 'Note',                              model: Note },
    { name: 'Marksheet',                           model: Marksheet },
    { name: 'FinalResult',                           model: FinalResult },
    { name: 'Notification',                            model: Notification },
    { name: 'EvaluationConfig',                          model: EvaluationConfig },
  ];

  for (const { name, model } of collections) {
    const result = await model.deleteMany({});
    console.log(`${name} deleted: ${result.deletedCount}`);
  }

  const remainingAdmins = await User.countDocuments({ role: 'admin' });
  console.log(`\nSuper admin account(s) preserved: ${remainingAdmins}`);

  console.log('\nCleanup complete. Database is ready for a fresh rebuild.');
  process.exit(0);
};

cleanup().catch((error) => {
  console.error('Cleanup failed:', error.message);
  process.exit(1);
});