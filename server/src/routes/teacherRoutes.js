const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
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
  getMarksheetsByCourse,
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
router.get('/courses/:courseId/attendance-dates', getAttendanceDates);     
router.get('/courses/:courseId/attendance/:date', getAttendanceForDate);   
router.patch('/courses/:courseId/attendance/:date', editAttendance);         


// Assignments
router.post('/courses/:courseId/assignments', createAssignment);
router.patch('/assignments/:id', updateAssignment);
router.get('/assignments/:id/submissions', getSubmissions);
router.patch('/submissions/:id/grade', gradeSubmission);
router.get('/courses/:courseId/assignments', getCourseAssignments);

// Notes
router.post('/courses/:courseId/notes', uploadNote);
router.delete('/notes/:id', deleteNote);
router.get('/notes', getMyNotes);
router.patch('/notes/:id', replaceNoteFile);

// Marksheets
router.post('/courses/:courseId/marksheets', uploadMarksheet);
router.post('/courses/:courseId/marksheets/bulk', bulkUploadMarksheets);
router.get('/courses/:courseId/marksheets', getMarksheetsByCourse);

module.exports = router;