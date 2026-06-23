const User = require('../models/User');
const Student = require('../models/Student');
const Teacher = require('../models/Teacher');
const Program = require('../models/Program');
const Batch = require('../models/Batch');
const generateTempPassword = require('../utils/generatePassword');
const sendEmail = require('../utils/email');
const Course = require('../models/Course');
const Enrollment = require('../models/Enrollment');
const Attendance = require('../models/Attendance');
const Marksheet = require('../models/Marksheet');
const FinalResult = require('../models/FinalResult');
const EvaluationConfig = require('../models/EvaluationConfig');

// ─── TEACHER MANAGEMENT ───────────────────────────────────────────

const createTeacher = async (req, res) => {
  try {
    const { name, email, department } = req.body;

    if (!name || !email || !department) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Name, email and department are required',
        },
      });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'DUPLICATE_EMAIL',
          message: 'An account with this email already exists',
        },
      });
    }

    const tempPassword = generateTempPassword();
    
console.log('Temp password for', email, ':', tempPassword);

    const user = await User.create({
      name,
      email,
      password: tempPassword,
      role: 'teacher',
      mustChangePassword: true,
    });

    const teacher = await Teacher.create({
      userId: user._id,
      department,
    });

    try {
        await sendEmail({
          to: email,
          subject: 'Welcome to SmartClass — Your Account Details',
          html: `
            <h2>Welcome to SmartClass, ${name}!</h2>
            <p>Your teacher account has been created by the administrator.</p>
            <br/>
            <p><strong>Email:</strong> ${email}</p>
            <p><strong>Temporary Password:</strong> ${tempPassword}</p>
            <br/>
            <p>Please log in and change your password immediately.</p>
          `,
        });
      } catch (emailError) {
        console.warn('Email could not be sent:', emailError.message);
      }

    res.status(201).json({
      success: true,
      data: {
        message: 'Teacher account created successfully',
        teacher: {
          id: user._id,
          name: user.name,
          email: user.email,
          department: teacher.department,
        },
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const getTeachers = async (req, res) => {
  try {
    const teachers = await Teacher.find()
      .populate('userId', 'name email status createdAt');

    res.status(200).json({
      success: true,
      data: { teachers },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const updateTeacher = async (req, res) => {
  try {
    const { name, department } = req.body;

    const teacher = await Teacher.findById(req.params.id);
    if (!teacher) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Teacher not found' },
      });
    }

    if (name) {
      await User.findByIdAndUpdate(teacher.userId, { name });
    }

    if (department) {
      teacher.department = department;
      await teacher.save();
    }

    res.status(200).json({
      success: true,
      data: { message: 'Teacher updated successfully' },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── STUDENT MANAGEMENT ───────────────────────────────────────────

const createStudent = async (req, res) => {
  try {
    const { name, email, rollNumber, programId, batchId } = req.body;

    if (!name || !email || !rollNumber || !programId || !batchId) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Name, email, rollNumber, programId and batchId are required',
        },
      });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'DUPLICATE_EMAIL',
          message: 'An account with this email already exists',
        },
      });
    }

    const program = await Program.findById(programId);
    if (!program) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Program not found' },
      });
    }

    const batch = await Batch.findById(batchId);
    if (!batch) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Batch not found' },
      });
    }

    const tempPassword = generateTempPassword();
console.log('Temp password for', email, ':', tempPassword);

    const user = await User.create({
      name,
      email,
      password: tempPassword,
      role: 'student',
      mustChangePassword: true,
    });

    const student = await Student.create({
      userId: user._id,
      programId,
      batchId,
      rollNumber,
    });

try {
  await sendEmail({
    to: email,
    subject: 'Welcome to SmartClass — Your Account Details',
    html: `
      <h2>Welcome to SmartClass, ${name}!</h2>
      <p>Your teacher account has been created by the administrator.</p>
      <br/>
      <p><strong>Email:</strong> ${email}</p>
      <p><strong>Temporary Password:</strong> ${tempPassword}</p>
      <br/>
      <p>Please log in and change your password immediately.</p>
    `,
  });
} catch (emailError) {
  console.warn('Email could not be sent:', emailError.message);
}
    res.status(201).json({
      success: true,
      data: {
        message: 'Student account created successfully',
        student: {
          id: user._id,
          name: user.name,
          email: user.email,
          rollNumber: student.rollNumber,
          program: program.name,
        },
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const getStudents = async (req, res) => {
  try {
    const filter = {};
    if (req.query.programId) filter.programId = req.query.programId;
    if (req.query.batchId) filter.batchId = req.query.batchId;

    const students = await Student.find(filter)
      .populate('userId', 'name email status createdAt')
      .populate('programId', 'name type')
      .populate('batchId', 'name currentTerm intakeYear');

    res.status(200).json({
      success: true,
      data: { students },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const updateStudent = async (req, res) => {
  try {
    const { name, rollNumber } = req.body;

    const student = await Student.findById(req.params.id);
    if (!student) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Student not found' },
      });
    }

    if (name) {
      await User.findByIdAndUpdate(student.userId, { name });
    }

    if (rollNumber) {
      student.rollNumber = rollNumber;
      await student.save();
    }

    res.status(200).json({
      success: true,
      data: { message: 'Student updated successfully' },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── ACCOUNT STATUS ───────────────────────────────────────────────

const updateUserStatus = async (req, res) => {
  try {
    const { status } = req.body;

    if (!['active', 'inactive', 'suspended'].includes(status)) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Status must be active, inactive or suspended',
        },
      });
    }

    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'User not found' },
      });
    }

    if (user.role === 'admin') {
      return res.status(403).json({
        success: false,
        error: {
          code: 'FORBIDDEN',
          message: 'Cannot change status of an admin account',
        },
      });
    }

    user.status = status;
    await user.save();

    res.status(200).json({
      success: true,
      data: {
        message: `User account ${status} successfully`,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── PROGRAM MANAGEMENT ──────────────────────────────────────────

const createProgram = async (req, res) => {
  try {
    const { name, type } = req.body;

    if (!name || !type) {
      return res.status(400).json({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'Name and type are required' },
      });
    }

    if (!['semester', 'year'].includes(type)) {
      return res.status(400).json({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'Type must be semester or year' },
      });
    }

    const program = await Program.create({ name, type });

    res.status(201).json({
      success: true,
      data: { program },
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        error: { code: 'DUPLICATE_NAME', message: 'A program with this name already exists' },
      });
    }
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const getPrograms = async (req, res) => {
  try {
    const programs = await Program.find({ isActive: true });

    res.status(200).json({
      success: true,
      data: { programs },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const updateProgram = async (req, res) => {
  try {
    const { name, isActive } = req.body;

    const program = await Program.findById(req.params.id);
    if (!program) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Program not found' },
      });
    }

    if (name) program.name = name;
    if (isActive !== undefined) program.isActive = isActive;
    await program.save();

    res.status(200).json({
      success: true,
      data: { program },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── BATCH MANAGEMENT ────────────────────────────────────────────

const createBatch = async (req, res) => {
  try {
    const { programId } = req.params;
    const { name, intakeYear } = req.body;

    if (!name || !intakeYear) {
      return res.status(400).json({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'Name and intakeYear are required' },
      });
    }

    const program = await Program.findById(programId);
    if (!program) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Program not found' },
      });
    }

    const batch = await Batch.create({ programId, name, intakeYear });

    res.status(201).json({
      success: true,
      data: { batch },
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        error: { code: 'DUPLICATE', message: 'A batch for this program and intake year already exists' },
      });
    }
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const getBatches = async (req, res) => {
  try {
    const batches = await Batch.find({ programId: req.params.programId })
      .populate('programId', 'name type totalTerms');

    res.status(200).json({
      success: true,
      data: { batches },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const getAllBatches = async (req, res) => {
  try {
    const batches = await Batch.find()
      .populate('programId', 'name type totalTerms');

    res.status(200).json({
      success: true,
      data: { batches },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const promoteBatch = async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id)
      .populate('programId', 'totalTerms name');

    if (!batch) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Batch not found' },
      });
    }

    if (batch.currentTerm >= batch.programId.totalTerms) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'PROMOTION_LIMIT',
          message: `Batch is already at the final term (${batch.programId.totalTerms}) of ${batch.programId.name}`,
        },
      });
    }

    const previousTerm = batch.currentTerm;
    batch.currentTerm += 1;
    await batch.save();

    // Auto-enroll all students in this batch into compulsory courses for the new term
    const newTermCourses = await Course.find({
      programId: batch.programId._id,
      term: batch.currentTerm,
      isElective: false,
      isActive: true,
    });

    const students = await Student.find({ batchId: batch._id });

    const enrollments = [];
    for (const student of students) {
      for (const course of newTermCourses) {
        enrollments.push({
          studentId: student._id,
          courseId: course._id,
          enrollmentType: 'compulsory',
        });
      }
    }

    if (enrollments.length > 0) {
      // insertMany with ordered: false continues even if some duplicates exist
      await Enrollment.insertMany(enrollments, { ordered: false }).catch(() => {});
    }

    res.status(200).json({
      success: true,
      data: {
        message: `Batch promoted from Term ${previousTerm} to Term ${batch.currentTerm}`,
        studentsAffected: students.length,
        coursesEnrolled: newTermCourses.length,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const resetUserPassword = async (req, res) => {
  try {
    const { email, newPassword } = req.body;

    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'User not found' },
      });
    }

    user.password = newPassword;
    user.mustChangePassword = true;
    await user.save();

    res.status(200).json({
      success: true,
      data: { message: `Password reset successfully for ${email}` },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── ACADEMIC OVERRIDES (FR-ADM-09) ──────────────────────────────

const overrideAttendance = async (req, res) => {
  try {
    const { status } = req.body;

    if (!['present', 'absent', 'late'].includes(status)) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Status must be present, absent or late',
        },
      });
    }

    const record = await Attendance.findById(req.params.id);
    if (!record) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Attendance record not found' },
      });
    }

    record.status = status;
    record.markedBy = req.user._id;
    await record.save();

    res.status(200).json({
      success: true,
      data: { message: 'Attendance overridden successfully', record },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const overrideMarksheet = async (req, res) => {
  try {
    const { internalExamMarks, internalExamTotalMarks, teacherEvaluationScore } = req.body;

    const marksheet = await Marksheet.findById(req.params.id);
    if (!marksheet) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Marksheet not found' },
      });
    }

    if (internalExamMarks !== undefined) marksheet.internalExamMarks = internalExamMarks;
    if (internalExamTotalMarks !== undefined) marksheet.internalExamTotalMarks = internalExamTotalMarks;
    if (teacherEvaluationScore !== undefined) marksheet.teacherEvaluationScore = teacherEvaluationScore;
    marksheet.uploadedBy = req.user._id;

    await marksheet.save();

    res.status(200).json({
      success: true,
      data: { message: 'Marksheet overridden successfully', marksheet },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── ENROLLMENT MANAGEMENT ───────────────────────────────────────
const manualEnroll = async (req, res) => {
  try {
    const { studentId, courseId } = req.body;

    const student = await Student.findById(studentId);
    if (!student) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Student not found' },
      });
    }

    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Course not found' },
      });
    }

    const enrollment = await Enrollment.create({
      studentId: student._id,
      courseId: course._id,
      enrollmentType: 'compulsory',
    });

    res.status(201).json({
      success: true,
      data: { message: 'Student enrolled successfully', enrollment },
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        error: { code: 'ALREADY_ENROLLED', message: 'Student is already enrolled in this course' },
      });
    }
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};


// ─── FINAL RESULTS (FR-ADM-12) ───────────────────────────────────

const uploadFinalResults = async (req, res) => {
  try {
    const { results } = req.body;

    // results = [{ studentId, term, overallStatus, publishedDate, courseResults: [{ courseId, status }] }]

    if (!results || !Array.isArray(results) || results.length === 0) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'results array is required',
        },
      });
    }

    const saved = await Promise.all(
      results.map(({ studentId, term, overallStatus, publishedDate, courseResults }) =>
        FinalResult.findOneAndUpdate(
          { studentId, term },
          {
            studentId,
            term,
            overallStatus,
            courseResults,
            publishedDate: new Date(publishedDate),
            enteredBy: req.user._id,
          },
          { upsert: true, new: true, runValidators: true }
        )
      )
    );

    res.status(200).json({
      success: true,
      data: {
        message: `Final results uploaded for ${saved.length} students`,
        results: saved,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── EVALUATION CONFIG (FR-ADM-06) ───────────────────────────────

const getEvaluationConfig = async (req, res) => {
  try {
    let config = await EvaluationConfig.findOne();

    if (!config) {
      config = {
        attendanceWeight: 25,
        internalExamWeight: 25,
        assignmentWeight: 25,
        teacherEvaluationWeight: 25,
      };
    }

    res.status(200).json({
      success: true,
      data: { config },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const updateEvaluationConfig = async (req, res) => {
  try {
    const {
      attendanceWeight,
      internalExamWeight,
      assignmentWeight,
      teacherEvaluationWeight,
    } = req.body;

    // Validate weights add up to 100
    const total =
      (attendanceWeight || 0) +
      (internalExamWeight || 0) +
      (assignmentWeight || 0) +
      (teacherEvaluationWeight || 0);

    if (total !== 100) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: `Weights must add up to 100. Current total: ${total}`,
        },
      });
    }

    const config = await EvaluationConfig.findOneAndUpdate(
      {},
      {
        attendanceWeight,
        internalExamWeight,
        assignmentWeight,
        teacherEvaluationWeight,
        updatedBy: req.user._id,
      },
      { upsert: true, new: true, runValidators: true }
    );

    res.status(200).json({
      success: true,
      data: {
        message: 'Evaluation config updated successfully',
        config,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── SYSTEM REPORTS (FR-ADM-07) ──────────────────────────────────

const getSystemReports = async (req, res) => {
  try {
    const [
      totalStudents,
      totalTeachers,
      totalPrograms,
      totalCourses,
      totalAttendanceRecords,
      totalAssignments,
      totalSubmissions,
    ] = await Promise.all([
      Student.countDocuments(),
      Teacher.countDocuments(),
      Program.countDocuments({ isActive: true }),
      Course.countDocuments({ isActive: true }),
      Attendance.countDocuments(),
      Assignment.countDocuments({ isActive: true }),
      Submission.countDocuments(),
    ]);

    // Attendance breakdown across the whole system
    const [presentCount, absentCount, lateCount] = await Promise.all([
      Attendance.countDocuments({ status: 'present' }),
      Attendance.countDocuments({ status: 'absent' }),
      Attendance.countDocuments({ status: 'late' }),
    ]);

    const overallAttendanceRate =
      totalAttendanceRecords > 0
        ? ((presentCount / totalAttendanceRecords) * 100).toFixed(2)
        : 0;

    // Assignment submission rate
    const submissionRate =
      totalAssignments > 0 && totalStudents > 0
        ? ((totalSubmissions / (totalAssignments * totalStudents)) * 100).toFixed(2)
        : 0;

    res.status(200).json({
      success: true,
      data: {
        overview: {
          totalStudents,
          totalTeachers,
          totalPrograms,
          totalCourses,
        },
        attendance: {
          totalRecords: totalAttendanceRecords,
          present: presentCount,
          absent: absentCount,
          late: lateCount,
          overallAttendanceRate: `${overallAttendanceRate}%`,
        },
        assignments: {
          totalAssignments,
          totalSubmissions,
          submissionRate: `${submissionRate}%`,
        },
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};



module.exports = {
  createTeacher, getTeachers, updateTeacher,
  createStudent, getStudents, updateStudent,
  updateUserStatus, resetUserPassword,
  createProgram, getPrograms, updateProgram,
  createBatch, getBatches, getAllBatches, promoteBatch,
  manualEnroll, 
  overrideAttendance, overrideMarksheet,
  uploadFinalResults,
  getEvaluationConfig, updateEvaluationConfig,
  getSystemReports,
};