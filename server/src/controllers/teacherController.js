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
module.exports = {
    takeAttendance,
    getAttendance,
    correctAttendance,
  };