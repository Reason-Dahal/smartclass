const express = require('express');
const router = express.Router();
const {
  createCourse,
  updateCourse,
  getCourses,
  deactivateCourse,
  getTeacherCourses,
  toggleEvaluation,
  getStudentCourses,
  getAvailableElectives,
  enrollElective,
   
} = require('../controllers/courseController');
const { protect, authorize } = require('../middleware/auth');

// Admin routes
router.post('/', protect, authorize('admin'), createCourse);
router.patch('/:id', protect, authorize('admin'), updateCourse);
router.delete('/:id', protect, authorize('admin'), deactivateCourse);
router.get('/', protect, authorize('admin'), getCourses);


// Teacher routes
router.get('/teacher/my-courses', protect, authorize('teacher'), getTeacherCourses);
router.patch('/teacher/:id/evaluation', protect, authorize('teacher'), toggleEvaluation);

// Student routes
router.get('/student/my-courses', protect, authorize('student'), getStudentCourses);
router.get('/student/electives', protect, authorize('student'), getAvailableElectives);
router.post('/student/enroll', protect, authorize('student'), enrollElective);

module.exports = router;