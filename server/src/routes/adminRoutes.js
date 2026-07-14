const express = require('express');
const router = express.Router();
const {
  createTeacher,
  getTeachers,
  updateTeacher,
  deactivateTeacher,
  createStudent,
  getStudents,
  updateStudent,
  deactivateStudent,
  updateUserStatus,
  resetUserPassword,
  manualEnroll,
  getCourseEnrollmentStatus,
  getAdminAttendanceDates,
  getAdminAttendanceForDate,
  adminEditAttendance,
  getAdminMarksheetsByCourse,
  adminBulkUploadMarksheets,
} = require('../controllers/adminController');
const { protect, authorize } = require('../middleware/auth');

// All admin routes require login + admin role
router.use(protect);
router.use(authorize('admin'));

// Teacher routes
router.post('/teachers', createTeacher);
router.get('/teachers', getTeachers);
router.patch('/teachers/:id', updateTeacher);
router.delete('/teachers/:id',   deactivateTeacher);


// Student routes
router.post('/students', createStudent);
router.get('/students', getStudents);
router.patch('/students/:id', updateStudent);
router.delete('/students/:id',   deactivateStudent);


// User status
router.patch('/users/:id/status', updateUserStatus);

//User
router.patch('/users/reset-password', resetUserPassword);

//Enroll
router.post('/enroll', manualEnroll);
router.get('/courses/:courseId/enrollment-status', getCourseEnrollmentStatus);

// Attendance override (full access — no ownership restriction)
router.get('/courses/:courseId/attendance-dates',   getAdminAttendanceDates);
router.get('/courses/:courseId/attendance/:date',   getAdminAttendanceForDate);
router.patch('/courses/:courseId/attendance/:date', adminEditAttendance);

// Marksheet override (full access — no ownership restriction)
router.get('/courses/:courseId/marksheets',       getAdminMarksheetsByCourse);
router.post('/courses/:courseId/marksheets/bulk', adminBulkUploadMarksheets);

module.exports = router;