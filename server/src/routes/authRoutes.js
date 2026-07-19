const express     = require('express');
const router      = express.Router();
const rateLimit    = require('express-rate-limit');
const {
  login,
  getMe,
  changePassword,
  forgotPassword,
  verifyOtp,
  resetPassword,
  registerFcmToken,
} = require('../controllers/authController');
const { protect } = require('../middleware/auth');

// RATE LIMITERS 
// Login — prevent password brute-forcing
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,   // 15 minutes
  max: 10,                     // 10 FAILED attempts per window per IP
  skipSuccessfulRequests: true, // successful logins don't count against the limit
  message: {
    success: false,
    error: {
      code:    'TOO_MANY_ATTEMPTS',
      message: 'Too many login attempts. Please try again in 15 minutes.',
    },
  },
  standardHeaders: true,
  legacyHeaders:   false,
});

// Forgot password — prevent OTP request spam
const forgotPasswordLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,   // 15 minutes
  max: 3,                      // 3 OTP requests per window per IP
  message: {
    success: false,
    error: {
      code:    'TOO_MANY_ATTEMPTS',
      message: 'Too many password reset requests. Please try again in 15 minutes.',
    },
  },
  standardHeaders: true,
  legacyHeaders:   false,
});

// Verify OTP — prevent brute-forcing the 6-digit code
const verifyOtpLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,   // 15 minutes
  max: 5,                      // 5 attempts per window per IP
  message: {
    success: false,
    error: {
      code:    'TOO_MANY_ATTEMPTS',
      message: 'Too many OTP verification attempts. Please request a new OTP.',
    },
  },
  standardHeaders: true,
  legacyHeaders:   false,
});

// ROUTES 
router.post('/login',           loginLimiter, login);
router.get('/me',               protect, getMe);
router.post('/change-password', protect, changePassword);
router.post('/fcm-token',       protect, registerFcmToken);

router.post('/forgot-password', forgotPasswordLimiter, forgotPassword);
router.post('/verify-otp',      verifyOtpLimiter, verifyOtp);
router.post('/reset-password',  resetPassword);

module.exports = router;