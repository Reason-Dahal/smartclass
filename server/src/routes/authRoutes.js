const express = require('express');
const router  = express.Router();
const {
  login,
  getMe,
  changePassword,
  forgotPassword,
  verifyOtp,
  resetPassword,
} = require('../controllers/authController');
const { protect } = require('../middleware/auth');

router.post('/login',           login);
router.get('/me',               protect, getMe);
router.post('/change-password', protect, changePassword);


router.post('/forgot-password', forgotPassword);
router.post('/verify-otp',      verifyOtp);
router.post('/reset-password',  resetPassword);

module.exports = router;