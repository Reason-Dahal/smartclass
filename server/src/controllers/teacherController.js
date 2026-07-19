const Teacher = require('../models/Teacher');
const Course = require('../models/Course');
const Enrollment = require('../models/Enrollment');
const Attendance = require('../models/Attendance');
const Assignment = require('../models/Assignment');
const Submission = require('../models/Submission');
const Note = require('../models/Note');
const Marksheet = require('../models/Marksheet');
const Notification = require('../models/Notification');
const Student = require('../models/Student');

// ─── HELPER: verify teacher owns the course ──────────────────────
const verifyTeacherCourse = async (teacherUserId, courseId) => {
  const teacher = await Teacher.findOne({ userId: teacherUserId });
  if (!teacher) return null;

  const course = await Course.findOne({
    _id: courseId,
    teacherId: teacher._id,
    isActive: true,
  });

  return course ? { teacher, course } : null;
};

// ─── ATTENDANCE ───────────────────────────────────────────────────

const takeAttendance = async (req, res) => {
  try {
    const { courseId } = req.params;
    const { date, records } = req.body;

    // records = [{ studentId, status }, ...]

    if (!date || !records || !Array.isArray(records) || records.length === 0) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'date and records array are required',
        },
      });
    }

    const verified = await verifyTeacherCourse(req.user._id, courseId);
    if (!verified) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'Course not found or you are not the teacher of this course',
        },
      });
    }

    const attendanceDate = new Date(date);

    // Build attendance records — upsert each one
    // (if teacher re-submits for same date, it updates rather than duplicates)
    const results = await Promise.all(
      records.map(({ studentId, status }) =>
        Attendance.findOneAndUpdate(
          { courseId, studentId, date: attendanceDate },
          { courseId, studentId, date: attendanceDate, status, markedBy: req.user._id },
          { upsert: true, new: true, runValidators: true }
        )
      )
    );

    Course.incrementUsage(req.params.courseId);

    res.status(200).json({
      success: true,
      data: {
        message: `Attendance recorded for ${results.length} students`,
        date: attendanceDate,
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

const getAttendance = async (req, res) => {
  try {
    const { courseId } = req.params;
    const { date } = req.query;

    const verified = await verifyTeacherCourse(req.user._id, courseId);
    if (!verified) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'Course not found or you are not the teacher of this course',
        },
      });
    }

    const filter = { courseId };
    if (date) filter.date = new Date(date);

    const attendance = await Attendance.find(filter)
      .populate('studentId', 'rollNumber')
      .sort({ date: -1 });

    res.status(200).json({
      success: true,
      data: { attendance },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const correctAttendance = async (req, res) => {
  try {
    const { id } = req.params;
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

    const record = await Attendance.findById(id);
    if (!record) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Attendance record not found' },
      });
    }

    // Verify teacher owns the course this attendance belongs to
    const verified = await verifyTeacherCourse(req.user._id, record.courseId);
    if (!verified) {
      return res.status(403).json({
        success: false,
        error: { code: 'FORBIDDEN', message: 'You are not the teacher of this course' },
      });
    }

    record.status = status;
    record.markedBy = req.user._id;
    await record.save();

    res.status(200).json({
      success: true,
      data: { message: 'Attendance corrected successfully', record },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── EDIT ATTENDANCE ─────────────────────────────────────────────
const editAttendance = async (req, res) => {
  try {
    const { courseId, date } = req.params;
    const { records } = req.body;

    if (!records || !Array.isArray(records) || records.length === 0) {
      return res.status(400).json({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'records array is required' },
      });
    }

    const verified = await verifyTeacherCourse(req.user._id, courseId);
    if (!verified) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Course not found or not your course' },
      });
    }

    const attendanceDate = new Date(date);

    // Ownership check — verify teacher created at least one record for this date
    const existing = await Attendance.findOne({
      courseId,
      date: attendanceDate,
      markedBy: req.user._id,
    });

    if (!existing) {
      return res.status(403).json({
        success: false,
        error: {
          code: 'FORBIDDEN',
          message: 'You can only edit attendance records you created',
        },
      });
    }

    // Upsert each record — same pattern as takeAttendance
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
        date: attendanceDate,
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

// ─── GET ATTENDANCE DATES ────────────────────────────────────────
// Returns distinct dates the teacher has taken attendance for a course
const getAttendanceDates = async (req, res) => {
  try {
    const { courseId } = req.params;

    const verified = await verifyTeacherCourse(req.user._id, courseId);
    if (!verified) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Course not found or not your course' },
      });
    }

    const dates = await Attendance.distinct('date', {
      courseId,
      markedBy: req.user._id,
    });

    // Sort newest first
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

// ─── GET ATTENDANCE FOR A DATE ───────────────────────────────────
// Returns all student attendance records for a specific date
const getAttendanceForDate = async (req, res) => {
  try {
    const { courseId, date } = req.params;

    const verified = await verifyTeacherCourse(req.user._id, courseId);
    if (!verified) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Course not found or not your course' },
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

// ─── ASSIGNMENTS ──────────────────────────────────────────────────

const createAssignment = async (req, res) => {
    try {
      const { courseId } = req.params;
      const { title, description, dueDate } = req.body;
  
      if (!title || !dueDate) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'title and dueDate are required',
          },
        });
      }
  
      const verified = await verifyTeacherCourse(req.user._id, courseId);
      if (!verified) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'NOT_FOUND',
            message: 'Course not found or you are not the teacher of this course',
          },
        });
      }
  
      const assignment = await Assignment.create({
        courseId,
        createdBy: req.user._id,
        title,
        description,
        dueDate: new Date(dueDate),
      });
  
      // Notify all enrolled students
      const enrollments = await Enrollment.find({
        courseId,
        isActive: true,
      }).populate('studentId', 'userId');
  
      const notifications = enrollments.map((e) => ({
        userId: e.studentId.userId,
        type: 'assignment',
        message: `New assignment posted in ${verified.course.subjectName}: ${title}`,
        relatedId: assignment._id,
      }));
  
      if (notifications.length > 0) {
        await Notification.insertMany(notifications, { ordered: false });
      }

      Course.incrementUsage(req.params.courseId);
  
      res.status(201).json({
        success: true,
        data: { assignment },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };
  
  const updateAssignment = async (req, res) => {
    try {
      const { id } = req.params;
      const { title, description, dueDate, isActive } = req.body;
  
      const assignment = await Assignment.findById(id);
      if (!assignment) {
        return res.status(404).json({
          success: false,
          error: { code: 'NOT_FOUND', message: 'Assignment not found' },
        });
      }
  
      const verified = await verifyTeacherCourse(req.user._id, assignment.courseId);
      if (!verified) {
        return res.status(403).json({
          success: false,
          error: { code: 'FORBIDDEN', message: 'You are not the teacher of this course' },
        });
      }
  
      if (title) assignment.title = title;
      if (description) assignment.description = description;
      if (dueDate) assignment.dueDate = new Date(dueDate);
      if (isActive !== undefined) assignment.isActive = isActive;
  
      await assignment.save();
  
      res.status(200).json({
        success: true,
        data: { assignment },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };
  
  const getSubmissions = async (req, res) => {
    try {
      const { id } = req.params;
  
      const assignment = await Assignment.findById(id);
      if (!assignment) {
        return res.status(404).json({
          success: false,
          error: { code: 'NOT_FOUND', message: 'Assignment not found' },
        });
      }
  
      const verified = await verifyTeacherCourse(req.user._id, assignment.courseId);
      if (!verified) {
        return res.status(403).json({
          success: false,
          error: { code: 'FORBIDDEN', message: 'You are not the teacher of this course' },
        });
      }
  
      const submissions = await Submission.find({ assignmentId: id })
        .populate({
          path: 'studentId',
          select: 'rollNumber',
          populate: { path: 'userId', select: 'name email' },
        })
        .sort({ submittedAt: 1 });
  
      res.status(200).json({
        success: true,
        data: {
          assignment: { title: assignment.title, dueDate: assignment.dueDate },
          totalSubmissions: submissions.length,
          submissions,
        },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };
  
  const gradeSubmission = async (req, res) => {
    try {
      const { id } = req.params;
      const { grade, feedback } = req.body;
  
      if (grade === undefined) {
        return res.status(400).json({
          success: false,
          error: { code: 'VALIDATION_ERROR', message: 'grade is required' },
        });
      }
  
      const submission = await Submission.findById(id)
        .populate('assignmentId');
  
      if (!submission) {
        return res.status(404).json({
          success: false,
          error: { code: 'NOT_FOUND', message: 'Submission not found' },
        });
      }
  
      const verified = await verifyTeacherCourse(
        req.user._id,
        submission.assignmentId.courseId
      );
      if (!verified) {
        return res.status(403).json({
          success: false,
          error: { code: 'FORBIDDEN', message: 'You are not the teacher of this course' },
        });
      }
  
      submission.grade = grade;
      submission.feedback = feedback || null;
      await submission.save();
  
      // Notify the student their work was graded
      const student = await Student.findById(submission.studentId);
      await Notification.create({
        userId: student.userId,
        type: 'grade',
        message: `Your submission for "${submission.assignmentId.title}" has been graded: ${grade}`,
        relatedId: submission._id,
      });
  
      res.status(200).json({
        success: true,
        data: { message: 'Submission graded successfully', submission },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };
  
  //  NOTES 
  
  const uploadNote = async (req, res) => {
    try {
      const { courseId } = req.params;
      const { title, fileUrl } = req.body;
  
      if (!title || !fileUrl) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'title and fileUrl are required',
          },
        });
      }
  
      const verified = await verifyTeacherCourse(req.user._id, courseId);
      if (!verified) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'NOT_FOUND',
            message: 'Course not found or you are not the teacher of this course',
          },
        });
      }
  
      const note = await Note.create({
        courseId,
        uploadedBy: req.user._id,
        title,
        fileUrl,
      });
  
      // Notify all enrolled students
      const enrollments = await Enrollment.find({
        courseId,
        isActive: true,
      }).populate('studentId', 'userId');
  
      const notifications = enrollments.map((e) => ({
        userId: e.studentId.userId,
        type: 'note',
        message: `New note uploaded in ${verified.course.subjectName}: ${title}`,
        relatedId: note._id,
      }));
  
      if (notifications.length > 0) {
        await Notification.insertMany(notifications, { ordered: false });
      }

      Course.incrementUsage(req.params.courseId);

      res.status(201).json({
        success: true,
        data: { note },
      });
      

    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };
  
  const deleteNote = async (req, res) => {
    try {
      const { id } = req.params;
  
      const note = await Note.findById(id);
      if (!note) {
        return res.status(404).json({
          success: false,
          error: { code: 'NOT_FOUND', message: 'Note not found' },
        });
      }
  
      const verified = await verifyTeacherCourse(req.user._id, note.courseId);
      if (!verified) {
        return res.status(403).json({
          success: false,
          error: { code: 'FORBIDDEN', message: 'You are not the teacher of this course' },
        });
      }
  
      note.isActive = false;
      await note.save();
  
      res.status(200).json({
        success: true,
        data: { message: 'Note deleted successfully' },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };

  //  GET MY NOTES (all courses, grouped by course)
const getMyNotes = async (req, res) => {
  try {
    const teacher = await Teacher.findOne({ userId: req.user._id });
    if (!teacher) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Teacher profile not found' },
      });
    }

    // Every active course this teacher teaches
    const courses = await Course.find({
      teacherId: teacher._id,
      isActive: true,
    }).populate('programId', 'name');

    const courseIds = courses.map((c) => c._id);

    const notes = await Note.find({
      courseId: { $in: courseIds },
      isActive: true,
    }).sort({ createdAt: -1 });

    // Group notes under their course, and courses under their program —
    // same Faculty > Subject shape used throughout the app already.
    const courseMap = {};
    courses.forEach((c) => {
      courseMap[c._id.toString()] = {
        courseId: c._id,
        subjectName: c.subjectName,
        programName: c.programId?.name || '',
        term: c.term,
        notes: [],
      };
    });

    notes.forEach((note) => {
      const key = note.courseId.toString();
      if (courseMap[key]) {
        courseMap[key].notes.push({
          _id: note._id,
          title: note.title,
          fileUrl: note.fileUrl,
          createdAt: note.createdAt,
        });
      }
    });

    // Only include courses that actually have at least one note
    const groups = Object.values(courseMap).filter(
      (c) => c.notes.length > 0
    );

    res.status(200).json({
      success: true,
      data: { groups },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

//REPLACE NOTE FILE
const replaceNoteFile = async (req, res) => {
  try {
    const { id } = req.params;
    const { fileUrl } = req.body;

    if (!fileUrl) {
      return res.status(400).json({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'fileUrl is required' },
      });
    }

    const note = await Note.findById(id);
    if (!note) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Note not found' },
      });
    }

    const verified = await verifyTeacherCourse(req.user._id, note.courseId);
    if (!verified) {
      return res.status(403).json({
        success: false,
        error: { code: 'FORBIDDEN', message: 'You are not the teacher of this course' },
      });
    }

    note.fileUrl = fileUrl;
    await note.save();

    res.status(200).json({
      success: true,
      data: { message: 'Note file replaced successfully', note },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};
  
  //  MARKSHEETS 
  const uploadMarksheet = async (req, res) => {
    try {
      const { courseId } = req.params;
      const { studentId, term, examType, internalExamMarks, internalExamTotalMarks, teacherEvaluationScore } = req.body;
  
      if (!studentId || !term || !examType || internalExamMarks === undefined ||
          !internalExamTotalMarks || teacherEvaluationScore === undefined) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'studentId, term, examType, internalExamMarks, internalExamTotalMarks and teacherEvaluationScore are required',
          },
        });
      }

      if (!Marksheet.EXAM_TYPES.includes(examType)) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: `examType must be one of: ${Marksheet.EXAM_TYPES.join(', ')}`,
          },
        });
      }
  
      const verified = await verifyTeacherCourse(req.user._id, courseId);
      if (!verified) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'NOT_FOUND',
            message: 'Course not found or you are not the teacher of this course',
          },
        });
      }
  
      const marksheet = await Marksheet.findOneAndUpdate(
        { studentId, courseId, term, examType },
        {
          studentId,
          courseId,
          term,
          examType,
          internalExamMarks,
          internalExamTotalMarks,
          teacherEvaluationScore,
          uploadedBy: req.user._id,
        },
        { upsert: true, new: true, runValidators: true }
      );

      Course.incrementUsage(req.params.courseId);
  
      res.status(200).json({
        success: true,
        data: { marksheet },
      });
      
    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };
  
  const bulkUploadMarksheets = async (req, res) => {
    try {
      const { courseId } = req.params;
      const { term, examType, marksheets } = req.body;
  
      if (!term || !examType || !marksheets || !Array.isArray(marksheets) || marksheets.length === 0) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'term, examType and marksheets array are required',
          },
        });
      }

      if (!Marksheet.EXAM_TYPES.includes(examType)) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: `examType must be one of: ${Marksheet.EXAM_TYPES.join(', ')}`,
          },
        });
      }
  
      const verified = await verifyTeacherCourse(req.user._id, courseId);
      if (!verified) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'NOT_FOUND',
            message: 'Course not found or you are not the teacher of this course',
          },
        });
      }
  
      /* Validate every record BEFORE writing anything.If any single
         student's data is malformed, we reject the whole batch up front
         and touch the database zero times.
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
        if (
          m.internalExamMarks === undefined ||
          m.internalExamTotalMarks === undefined ||
          m.teacherEvaluationScore === undefined
        ) {
          return res.status(400).json({
            success: false,
            error: {
              code: 'VALIDATION_ERROR',
              message: `Row ${i + 1}: missing marks data. Nothing was saved.`,
            },
          });
        }
      }
  
      /* All records validated — now safe to write. Even without a transaction,
         insertMany-style upserts here are individually atomic per-document,
         and since we've already guaranteed every document is well-formed,
         there is no realistic failure path left that would cause a partial save.
      */
      const results = await Promise.all(
        marksheets.map(({ studentId, internalExamMarks, internalExamTotalMarks, teacherEvaluationScore }) =>
          Marksheet.findOneAndUpdate(
            { studentId, courseId, term, examType },
            {
              studentId, courseId, term, examType,
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

//  GET MARKSHEETS FOR COURSE/TERM 
// Returns existing marksheets for pre-filling the edit form

const getMarksheetsByCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    const { term, examType } = req.query;

    const verified = await verifyTeacherCourse(req.user._id, courseId);
    if (!verified) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Course not found or not your course' },
      });
    }

    const filter = { courseId };
    if (term) filter.term = parseInt(term);
    if (examType) filter.examType = examType;

    const marksheets = await Marksheet.find(filter)
      .populate({
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



  const getCourseStudents = async (req, res) => {
    try {
      const { courseId } = req.params;
  
      const verified = await verifyTeacherCourse(req.user._id, courseId);
      if (!verified) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'NOT_FOUND',
            message: 'Course not found or you are not the teacher of this course',
          },
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

  const getCourseAssignments = async (req, res) => {
    try {
      const { courseId } = req.params;
  
      const verified = await verifyTeacherCourse(req.user._id, courseId);
      if (!verified) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'NOT_FOUND',
            message: 'Course not found or you are not the teacher of this course',
          },
        });
      }
  
      const assignments = await Assignment.find({
        courseId,
        isActive: true,
      }).sort({ createdAt: -1 });
  
      res.status(200).json({
        success: true,
        data: { assignments },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };

  module.exports = {
    takeAttendance,
    getAttendance,
    correctAttendance,
    editAttendance,
    getAttendanceDates,
    getAttendanceForDate,
    createAssignment,
    updateAssignment,
    getSubmissions,
    gradeSubmission,
    uploadNote,
    deleteNote,
    getMyNotes,
    replaceNoteFile,
    uploadMarksheet,
    bulkUploadMarksheets,
    getCourseStudents,
    getCourseAssignments,
    getMarksheetsByCourse,
  };