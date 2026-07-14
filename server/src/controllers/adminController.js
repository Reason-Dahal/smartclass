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
const Assignment = require('../models/Assignment');
const Submission = require('../models/Submission');
// const { uploadToCloudinary } = require('../utils/upload');
const { uploadToCloudinary, uploadResultToCloudinary } = require('../utils/upload');

//TEACHER MANAGEMENT 

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
    


    const user = await User.create({
      name,
      email,
      password: tempPassword,
      role: 'teacher',
      mustChangePassword: true,
      tempPassword: tempPassword,
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
      .populate('userId', 'name email role status createdAt');

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
    const { name, email, department } = req.body;

    const teacher = await Teacher.findById(req.params.id);
    if (!teacher) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Teacher not found' },
      });
    }

    // Check email not taken by another user
    if (email) {
      const existing = await User.findOne({
        email: email.toLowerCase().trim(),
        _id: { $ne: teacher.userId },
      });
      if (existing) {
        return res.status(400).json({
          success: false,
          error: { code: 'DUPLICATE_EMAIL', message: 'Email already in use' },
        });
      }
    }

    // Update User document
    const userUpdate = {};
    if (name)  userUpdate.name  = name.trim();
    if (email) userUpdate.email = email.toLowerCase().trim();
    if (Object.keys(userUpdate).length > 0) {
      await User.findByIdAndUpdate(teacher.userId, userUpdate);
    }

    // Update Teacher document
    if (department) {
      teacher.department = department.trim();
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

//EDIT TEACHER 
const editTeacher = async (req, res) => {
  try {
    const { name, email, department } = req.body;

    const teacher = await Teacher.findById(req.params.id).populate('userId');
    if (!teacher) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Teacher not found' },
      });
    }

    // Update User document (name and email)
    if (name || email) {
      const updateData = {};
      if (name)  updateData.name  = name.trim();
      if (email) updateData.email = email.toLowerCase().trim();

      // Check email is not already taken by another user
      if (email) {
        const existing = await User.findOne({
          email: email.toLowerCase().trim(),
          _id: { $ne: teacher.userId._id },
        });
        if (existing) {
          return res.status(400).json({
            success: false,
            error: { code: 'DUPLICATE_EMAIL', message: 'Email already in use' },
          });
        }
      }

      await User.findByIdAndUpdate(teacher.userId._id, updateData);
    }

    // Update Teacher document (department)
    if (department) {
      teacher.department = department.trim();
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

// DEACTIVATE TEACHER 
const deactivateTeacher = async (req, res) => {
  try {
    const teacher = await Teacher.findById(req.params.id);
    if (!teacher) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Teacher not found' },
      });
    }

    await User.findByIdAndUpdate(teacher.userId, { status: 'inactive' });

    res.status(200).json({
      success: true,
      data: { message: 'Teacher deactivated successfully' },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

//  STUDENT MANAGEMENT 

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


    const user = await User.create({
      name,
      email,
      password: tempPassword,
      role: 'student',
      mustChangePassword: true,
      tempPassword: tempPassword,
    });

    const student = await Student.create({
      userId: user._id,
      programId,
      batchId,
      rollNumber,
    });

    // Auto-enroll student into all compulsory courses for their program + current term
    const compulsoryCourses = await Course.find({
      programId,
      term: batch.currentTerm,
      isElective: false,
      isActive: true,
    });

    if (compulsoryCourses.length > 0) {
      const enrollments = compulsoryCourses.map((course) => ({
        studentId: student._id,
        courseId: course._id,
        enrollmentType: 'compulsory',
      }));

      // ordered: false — continues even if a duplicate somehow already exists
      await Enrollment.insertMany(enrollments, { ordered: false }).catch(() => {});
    }

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
      .populate('userId', 'name email role status createdAt')
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
    const { name, email, rollNumber, programId, batchId } = req.body;

    const student = await Student.findById(req.params.id);
    if (!student) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Student not found' },
      });
    }

    // Check email not taken by another user
    if (email) {
      const existing = await User.findOne({
        email: email.toLowerCase().trim(),
        _id: { $ne: student.userId },
      });
      if (existing) {
        return res.status(400).json({
          success: false,
          error: { code: 'DUPLICATE_EMAIL', message: 'Email already in use' },
        });
      }
    }

    // Check roll number not taken by another student
    if (rollNumber) {
      const existing = await Student.findOne({
        rollNumber: rollNumber.trim(),
        _id: { $ne: student._id },
      });
      if (existing) {
        return res.status(400).json({
          success: false,
          error: { code: 'DUPLICATE_ROLL', message: 'Roll number already in use' },
        });
      }
    }

    // Update User document
    const userUpdate = {};
    if (name)  userUpdate.name  = name.trim();
    if (email) userUpdate.email = email.toLowerCase().trim();
    if (Object.keys(userUpdate).length > 0) {
      await User.findByIdAndUpdate(student.userId, userUpdate);
    }

    // Update Student document
    if (rollNumber) student.rollNumber = rollNumber.trim();
    if (programId)  student.programId  = programId;
    if (batchId)    student.batchId    = batchId;
    await student.save();

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
const deactivateStudent = async (req, res) => {
  try {
    const student = await Student.findById(req.params.id);
    if (!student) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Student not found' },
      });
    }

    await User.findByIdAndUpdate(student.userId, { status: 'inactive' });

    res.status(200).json({
      success: true,
      data: { message: 'Student deactivated successfully' },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};
// ACCOUNT STATUS

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

//PROGRAM MANAGEMENT 

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
    const programs = await Program.find()

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

const deactivateProgram = async (req, res) => {
  try {
    const program = await Program.findById(req.params.id);
    if (!program) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Program not found' },
      });
    }

    program.isActive = false;
    await program.save();

    res.status(200).json({
      success: true,
      data: { message: 'Program deactivated successfully' },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// BATCH MANAGEMENT

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

// UPDATE BATCH 
const updateBatch = async (req, res) => {
  try {
    const { name, intakeYear, isActive } = req.body;

    const batch = await Batch.findById(req.params.id);
    if (!batch) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Batch not found' },
      });
    }

    if (name)       batch.name       = name.trim();
    if (intakeYear) batch.intakeYear = intakeYear;
    if (isActive !== undefined) batch.isActive = isActive;
    await batch.save();

    res.status(200).json({
      success: true,
      data: { message: 'Batch updated successfully' },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

//  DEACTIVATE BATCH 
const deactivateBatch = async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Batch not found' },
      });
    }

    batch.isActive = false;
    await batch.save();

    res.status(200).json({
      success: true,
      data: { message: 'Batch deactivated successfully' },
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

//ACADEMIC OVERRIDES 

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

//  ADMIN  ATTENDANCE OVERRIDE 

// Validates a date string is well-formed before it ever reaches MongoDB
const isValidDateString = (value) => {
  if (!value || typeof value !== 'string') return false;
  const parsed = new Date(value);
  return !isNaN(parsed.getTime());
};

// Validates term is a sane positive integer
const isValidTerm = (value) => {
  const num = Number(value);
  return Number.isInteger(num) && num >= 1 && num <= 12;
};

const getAdminCourseStudents = async (req, res) => {
  try {
    const { courseId } = req.params;

    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Course not found' },
      });
    }

    const enrollments = await Enrollment.find({
      courseId,
      isActive: true,
    }).populate({
      path: 'studentId',
      select: 'rollNumber userId',
      populate: { path: 'userId', select: 'name email' },
    });

    const students = enrollments.map((e) => ({
      studentId: e.studentId._id,
      rollNumber: e.studentId.rollNumber,
      name: e.studentId.userId?.name || '',
      email: e.studentId.userId?.email || '',
    }));

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

const getAdminAttendanceDates = async (req, res) => {
  try {
    const { courseId } = req.params;

    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Course not found' },
      });
    }

    const dates = await Attendance.distinct('date', { courseId });
    dates.sort((a, b) => new Date(b) - new Date(a));

    res.status(200).json({
      success: true,
      data: { dates },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const getAdminAttendanceForDate = async (req, res) => {
  try {
    const { courseId, date } = req.params;

    if (!isValidDateString(date)) {
      return res.status(400).json({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'Invalid date format' },
      });
    }

    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Course not found' },
      });
    }

    const attendanceDate = new Date(date);
    const records = await Attendance.find({
      courseId,
      date: attendanceDate,
    }).populate({
      path: 'studentId',
      populate: { path: 'userId', select: 'name' },
    });

    res.status(200).json({
      success: true,
      data: { records },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const adminEditAttendance = async (req, res) => {
  try {
    const { courseId, date } = req.params;
    const { records } = req.body;

    if (!isValidDateString(date)) {
      return res.status(400).json({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'Invalid date format' },
      });
    }

    if (!records || !Array.isArray(records) || records.length === 0) {
      return res.status(400).json({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'records array is required' },
      });
    }

    // Validate every record's shape before touching the database —
    // same principle as the marksheet fix: reject bad input up front,
    // never partially write.
    const validStatuses = ['present', 'absent', 'late'];
    for (let i = 0; i < records.length; i++) {
      const r = records[i];
      if (!r.studentId || typeof r.studentId !== 'string') {
        return res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: `Row ${i + 1}: missing or invalid studentId. Nothing was saved.`,
          },
        });
      }
      if (!validStatuses.includes(r.status)) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: `Row ${i + 1}: status must be present, absent, or late. Nothing was saved.`,
          },
        });
      }
    }

    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Course not found' },
      });
    }

    const attendanceDate = new Date(date);

    const results = await Promise.all(
      records.map(({ studentId, status }) =>
        Attendance.findOneAndUpdate(
          { courseId, studentId, date: attendanceDate },
          { courseId, studentId, date: attendanceDate, status, markedBy: req.user._id },
          { upsert: true, new: true, runValidators: true }
        )
      )
    );

    res.status(200).json({
      success: true,
      data: {
        message: `Attendance updated for ${results.length} students`,
        records: results,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ADMIN MARKSHEET OVERRIDE 

const getAdminMarksheetsByCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    const { term } = req.query;

    if (term !== undefined && !isValidTerm(term)) {
      return res.status(400).json({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'Invalid term value' },
      });
    }

    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Course not found' },
      });
    }

    const filter = { courseId };
    if (term !== undefined) filter.term = parseInt(term);

    const marksheets = await Marksheet.find(filter).populate({
      path: 'studentId',
      populate: { path: 'userId', select: 'name' },
    });

    res.status(200).json({
      success: true,
      data: { marksheets },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const adminBulkUploadMarksheets = async (req, res) => {
  try {
    const { courseId } = req.params;
    const { term, marksheets } = req.body;

    if (!isValidTerm(term)) {
      return res.status(400).json({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'Invalid or missing term' },
      });
    }

    if (!marksheets || !Array.isArray(marksheets) || marksheets.length === 0) {
      return res.status(400).json({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'marksheets array is required' },
      });
    }

    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Course not found' },
      });
    }

    /* 
     Validate every record before writing anything — prevents partial
     saves without relying on transactions (M0 tier doesn't support them
     reliably — see teacherController.bulkUploadMarksheets for the
     full reasoning behind this pattern).
    */
    for (let i = 0; i < marksheets.length; i++) {
      const m = marksheets[i];
      if (!m.studentId || typeof m.studentId !== 'string' || m.studentId.trim() === '') {
        return res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: `Row ${i + 1}: missing or invalid studentId. Nothing was saved.`,
          },
        });
      }
      const numericFields = [
        m.internalExamMarks,
        m.internalExamTotalMarks,
        m.teacherEvaluationScore,
      ];
      if (numericFields.some((v) => v === undefined || v === null || isNaN(Number(v)))) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: `Row ${i + 1}: marks values must be valid numbers. Nothing was saved.`,
          },
        });
      }
    }

    const results = await Promise.all(
      marksheets.map(({ studentId, internalExamMarks, internalExamTotalMarks, teacherEvaluationScore }) =>
        Marksheet.findOneAndUpdate(
          { studentId, courseId, term },
          {
            studentId, courseId, term,
            internalExamMarks, internalExamTotalMarks,
            teacherEvaluationScore,
            uploadedBy: req.user._id,
          },
          { upsert: true, new: true, runValidators: true }
        )
      )
    );

    res.status(200).json({
      success: true,
      data: {
        message: `Marksheets uploaded for ${results.length} students`,
        marksheets: results,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

//  ENROLLMENT MANAGEMENT 
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


const getCourseEnrollmentStatus = async (req, res) => {
  try {
    const { courseId } = req.params;

    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Course not found' },
      });
    }

    // All active students matching this course's program + term
    const candidateStudents = await Student.find({ programId: course.programId })
      .populate('batchId', 'currentTerm')
      .populate('userId', 'name email status')
      .select('rollNumber batchId userId');

    const eligibleStudents = candidateStudents.filter(
      (student) =>
        student.userId?.status === 'active' &&
        student.batchId?.currentTerm === course.term
    );

    // Existing enrollments for this course, so we know who's already in
    const existingEnrollments = await Enrollment.find({
      courseId,
      isActive: true,
    }).select('studentId');

    const enrolledStudentIds = new Set(
      existingEnrollments.map((e) => e.studentId.toString())
    );

    const enrolled = [];
    const notEnrolled = [];

    for (const student of eligibleStudents) {
      const entry = {
        studentId: student._id,
        rollNumber: student.rollNumber,
        name: student.userId?.name || '',
        email: student.userId?.email || '',
      };

      if (enrolledStudentIds.has(student._id.toString())) {
        enrolled.push(entry);
      } else {
        notEnrolled.push(entry);
      }
    }

    res.status(200).json({
      success: true,
      data: {
        course: {
          id: course._id,
          subjectName: course.subjectName,
          term: course.term,
          isElective: course.isElective,
        },
        enrolled,
        notEnrolled,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};


// FINAL RESULTS 

const uploadFinalResults = async (req, res) => {
  try {
    const { programId, term } = req.body;

    if (!programId || !term) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Program and term are required',
        },
      });
    }

    // Validate program exists
    const program = await Program.findById(programId);
    if (!program) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Program not found' },
      });
    }

    // Validate file was uploaded
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: { code: 'NO_FILE', message: 'Result file is required' },
      });
    }

    // Determine file type
    const mimetype = req.file.mimetype;
    const fileType = mimetype.includes('pdf') ? 'pdf' : 'docx';

    // Upload file to Cloudinary
    const fileUrl = await uploadResultToCloudinary(req.file.buffer, fileType);

    // Upsert — overwrite if result for this program+term already exists
    await FinalResult.findOneAndUpdate(
      { programId, term: parseInt(term) },
      {
        fileUrl,
        fileType,
        publishedDate: new Date(),
        uploadedBy: req.user._id,
      },
      { upsert: true, new: true }
    );

    res.status(200).json({
      success: true,
      data: { message: 'Final result published successfully' },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// EVALUATION CONFIG 

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

// SYSTEM REPORTS

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
  getCourseEnrollmentStatus, 
  getAdminCourseStudents,
  overrideAttendance,
  overrideMarksheet,
  getAdminAttendanceDates,
  getAdminAttendanceForDate,
  adminEditAttendance,
  getAdminMarksheetsByCourse,
  adminBulkUploadMarksheets,
  uploadFinalResults,
  getEvaluationConfig, updateEvaluationConfig,
  getSystemReports,
  editTeacher,
  deactivateTeacher,
  deactivateStudent,
  updateBatch,
  deactivateBatch,
  deactivateProgram
};