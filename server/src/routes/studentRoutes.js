const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
  getMyAttendance,
  getMyAssignments,
  submitAssignment,
  deleteSubmission, 
  getMyNotes,
  getMyMarksheets,
  getMyFinalResults,
  getEvaluationIndicator,
  getMyNotifications,
  markNotificationRead,
  markAllNotificationsRead,
} = require('../controllers/studentController');

router.use(protect);
router.use(authorize('student'));

// Attendance
router.get('/attendance', getMyAttendance);

// Assignments
router.get('/assignments', getMyAssignments);
router.post('/assignments/:id/submit', submitAssignment);
router.delete('/submissions/:id',    deleteSubmission);

// Notes
router.get('/notes', getMyNotes);

// Marksheets
router.get('/marksheets', getMyMarksheets);

// Final results
router.get('/final-results', getMyFinalResults);

// Evaluation indicator
router.get('/evaluation', getEvaluationIndicator);

// Notifications
router.get('/notifications', getMyNotifications);
router.patch('/notifications/:id/read', markNotificationRead);
router.patch('/notifications/read-all', markAllNotificationsRead);

module.exports = router;