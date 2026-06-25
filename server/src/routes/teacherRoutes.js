const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
  takeAttendance,
  getAttendance,
  correctAttendance,
  createAssignment,
  updateAssignment,
  getSubmissions,
  gradeSubmission,
  uploadNote,
  deleteNote,
  uploadMarksheet,
  bulkUploadMarksheets,
  getCourseStudents,
  getCourseAssignments,
} = require('../controllers/teacherController');

router.use(protect);
router.use(authorize('teacher'));

// Attendance
router.post('/courses/:courseId/attendance', takeAttendance);
router.get('/courses/:courseId/attendance', getAttendance);
router.patch('/attendance/:id', correctAttendance);
router.get('/courses/:courseId/students', getCourseStudents);

// Assignments
router.post('/courses/:courseId/assignments', createAssignment);
router.patch('/assignments/:id', updateAssignment);
router.get('/assignments/:id/submissions', getSubmissions);
router.patch('/submissions/:id/grade', gradeSubmission);
router.get('/courses/:courseId/assignments', getCourseAssignments);

// Notes
router.post('/courses/:courseId/notes', uploadNote);
router.delete('/notes/:id', deleteNote);

// Marksheets
router.post('/courses/:courseId/marksheets', uploadMarksheet);
router.post('/courses/:courseId/marksheets/bulk', bulkUploadMarksheets);

module.exports = router;