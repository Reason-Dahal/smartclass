const express = require('express');
const router = express.Router();
const {
  createTeacher,
  getTeachers,
  updateTeacher,
  createStudent,
  getStudents,
  updateStudent,
  updateUserStatus,
  resetUserPassword,
  manualEnroll,
} = require('../controllers/adminController');
const { protect, authorize } = require('../middleware/auth');

// All admin routes require login + admin role
router.use(protect);
router.use(authorize('admin'));

// Teacher routes
router.post('/teachers', createTeacher);
router.get('/teachers', getTeachers);
router.patch('/teachers/:id', updateTeacher);

// Student routes
router.post('/students', createStudent);
router.get('/students', getStudents);
router.patch('/students/:id', updateStudent);


// User status
router.patch('/users/:id/status', updateUserStatus);

//User
router.patch('/users/reset-password', resetUserPassword);

//Enroll
router.post('/enroll', manualEnroll);

module.exports = router;