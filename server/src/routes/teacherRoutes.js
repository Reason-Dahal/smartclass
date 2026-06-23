const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
  takeAttendance,
  getAttendance,
  correctAttendance,
} = require('../controllers/teacherController');

router.use(protect);
router.use(authorize('teacher'));

// Attendance
router.post('/courses/:courseId/attendance', takeAttendance);
router.get('/courses/:courseId/attendance', getAttendance);
router.patch('/attendance/:id', correctAttendance);

module.exports = router;