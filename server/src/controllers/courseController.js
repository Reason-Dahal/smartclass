const Course = require('../models/Course');
const Teacher = require('../models/Teacher');
const Program = require('../models/Program');
const Enrollment = require('../models/Enrollment');
const Student = require('../models/Student');

// ─── ADMIN: CREATE COURSE ─────────────────────────────────────────

const createCourse = async (req, res) => {
  try {
    const { programId, teacherId, subjectName, term, isElective } = req.body;

    if (!programId || !teacherId || !subjectName || !term) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'programId, teacherId, subjectName and term are required',
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

    if (term < 1 || term > program.totalTerms) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: `Term must be between 1 and ${program.totalTerms} for this program`,
        },
      });
    }

    const teacher = await Teacher.findById(teacherId);
    if (!teacher) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Teacher not found' },
      });
    }

    const course = await Course.create({
      programId,
      teacherId,
      subjectName,
      term,
      isElective: isElective || false,
    });

    await course.populate([
      { path: 'programId', select: 'name type' },
      { path: 'teacherId', select: 'userId department', populate: { path: 'userId', select: 'name email' } },
    ]);

    res.status(201).json({
      success: true,
      data: { course },
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'DUPLICATE',
          message: 'A course with this subject already exists for this program and term',
        },
      });
    }
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── ADMIN: UPDATE,DEACTIVATE,GET COURSE ─────────────────────────────────────────

const updateCourse = async (req, res) => {
  try {
    const { teacherId, subjectName, isActive,isElective } = req.body;

    const course = await Course.findById(req.params.id);
    if (!course) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Course not found' },
      });
    }

    if (teacherId) {
      const teacher = await Teacher.findById(teacherId);
      if (!teacher) {
        return res.status(404).json({
          success: false,
          error: { code: 'NOT_FOUND', message: 'Teacher not found' },
        });
      }
      course.teacherId = teacherId;
    }

    if (subjectName) course.subjectName = subjectName;
    if (isElective !== undefined) course.isElective = isElective;
    if (isActive !== undefined) course.isActive = isActive;

    await course.save();

    res.status(200).json({
      success: true,
      data: { course },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};
// ─── DEACTIVATE COURSE ───────────────────────────────────────────
const deactivateCourse = async (req, res) => {
  try {
    const course = await Course.findById(req.params.id);
    if (!course) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Course not found' },
      });
    }

    course.isActive = false;
    await course.save();

    res.status(200).json({
      success: true,
      data: { message: 'Course deactivated successfully' },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const getCourses = async (req, res) => {
  try {
    const courses = await Course.find()
      .populate('programId', 'name type')
      .populate({
        path: 'teacherId',
        populate: { path: 'userId', select: 'name' },
      })
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: { courses },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── TEACHER: GET OWN COURSES ─────────────────────────────────────

const getTeacherCourses = async (req, res) => {
  try {
    const teacher = await Teacher.findOne({ userId: req.user._id });
    if (!teacher) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Teacher profile not found' },
      });
    }

    // V2 — sort by usageCount descending (most used first)
    const courses = await Course.find({
      teacherId: teacher._id,
      isActive:  true,
    })
      .populate('programId', 'name type totalTerms')
      .sort({ usageCount: -1, lastUsedAt: -1 });

    // Add student count to each course
    const coursesWithCount = await Promise.all(
      courses.map(async (course) => {
        const studentCount = await Enrollment.countDocuments({
          courseId: course._id,
          isActive: true,
        });
        return {
          ...course.toObject(),
          studentCount,
        };
      })
    );

    // V2 — top 5 most used as shortcuts for home tab
    const shortcuts = coursesWithCount.slice(0, 5);

    res.status(200).json({
      success: true,
      data: {
        courses:   coursesWithCount,
        shortcuts,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── TEACHER: TOGGLE EVALUATION INDICATOR ────────────────────────

const toggleEvaluation = async (req, res) => {
  try {
    const { evaluationEnabled } = req.body;

    if (evaluationEnabled === undefined) {
      return res.status(400).json({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'evaluationEnabled is required' },
      });
    }

    const teacher = await Teacher.findOne({ userId: req.user._id });
    if (!teacher) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Teacher profile not found' },
      });
    }

    const course = await Course.findOne({
      _id: req.params.id,
      teacherId: teacher._id,
    });

    if (!course) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'Course not found or you are not the teacher of this course',
        },
      });
    }

    course.evaluationEnabled = evaluationEnabled;
    await course.save();

    res.status(200).json({
      success: true,
      data: {
        message: `Evaluation indicator ${evaluationEnabled ? 'enabled' : 'disabled'} for ${course.subjectName}`,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── STUDENT: GET OWN ENROLLED COURSES ───────────────────────────

const getStudentCourses = async (req, res) => {
  try {
    const student = await Student.findOne({ userId: req.user._id });
    if (!student) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Student profile not found' },
      });
    }

    const enrollments = await Enrollment.find({
      studentId: student._id,
      isActive: true,
    }).populate({
      path: 'courseId',
      match: { isActive: true },
      populate: [
        { path: 'programId', select: 'name type' },
        {
          path: 'teacherId',
          select: 'userId department',
          populate: { path: 'userId', select: 'name' },
        },
      ],
    });

    // Filter out any enrollments where the course was inactive (populate returns null)
    const courses = enrollments
      .filter((e) => e.courseId !== null)
      .map((e) => ({
        enrollmentId: e._id,
        enrollmentType: e.enrollmentType,
        enrolledAt: e.enrolledAt,
        course: e.courseId,
      }));

    res.status(200).json({
      success: true,
      data: { courses },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── STUDENT: GET AVAILABLE ELECTIVES ────────────────────────────

const getAvailableElectives = async (req, res) => {
  try {
    const student = await Student.findOne({ userId: req.user._id })
      .populate('batchId', 'currentTerm');

    if (!student) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Student profile not found' },
      });
    }

    // Get courses the student is already enrolled in
    const existingEnrollments = await Enrollment.find({
      studentId: student._id,
      isActive: true,
    }).select('courseId');

    const enrolledCourseIds = existingEnrollments.map((e) => e.courseId.toString());

    // Find elective courses for this student's program and current term
    // that they are not already enrolled in
    const electives = await Course.find({
      programId: student.programId,
      term: student.batchId.currentTerm,
      isElective: true,
      isActive: true,
      _id: { $nin: enrolledCourseIds },
    }).populate('teacherId', 'userId department');

    res.status(200).json({
      success: true,
      data: { electives },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── STUDENT: ENROLL IN ELECTIVE ─────────────────────────────────

const enrollElective = async (req, res) => {
  try {
    const { courseId } = req.body;

    const student = await Student.findOne({ userId: req.user._id })
      .populate('batchId', 'currentTerm');

    if (!student) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Student profile not found' },
      });
    }

    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Course not found' },
      });
    }

    // Verify the course is actually an elective for their program and current term
    if (
      !course.isElective ||
      course.programId.toString() !== student.programId.toString() ||
      course.term !== student.batchId.currentTerm
    ) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'INVALID_ENROLLMENT',
          message: 'This course is not an available elective for your current program and term',
        },
      });
    }

    const enrollment = await Enrollment.create({
      studentId: student._id,
      courseId,
      enrollmentType: 'elective',
    });

    res.status(201).json({
      success: true,
      data: { message: `Successfully enrolled in ${course.subjectName}`, enrollment },
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        error: { code: 'ALREADY_ENROLLED', message: 'You are already enrolled in this course' },
      });
    }
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

module.exports = {
  createCourse,
  updateCourse,
  deactivateCourse,
  getCourses,
  getTeacherCourses,
  toggleEvaluation,
  getStudentCourses,
  getAvailableElectives,
  enrollElective,
};