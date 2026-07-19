const User = require('../models/User');
const { generateToken } = require('../utils/jwt.js');
const sendEmail = require('../utils/email');
const crypto    = require('crypto');

// Hash OTP/reset tokens before storing — protects against DB leaks.
const hashToken = (token) =>
  crypto.createHash('sha256').update(token).digest('hex');

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Email and password are required',
        },
      });
    }

    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'INVALID_CREDENTIALS',
          message: 'Invalid email or password',
        },
      });
    }

    if (user.status !== 'active') {
      return res.status(403).json({
        success: false,
        error: {
          code: 'ACCOUNT_SUSPENDED',
          message: 'Your account has been suspended. Contact admin.',
        },
      });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'INVALID_CREDENTIALS',
          message: 'Invalid email or password',
        },
      });
    }

    const token = generateToken(user._id, user.role);

    res.status(200).json({
      success: true,
      data: {
        token,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          role: user.role,
          mustChangePassword: user.mustChangePassword,
        },
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const getMe = async (req, res) => {
  try {
    res.status(200).json({
      success: true,
      data: { user: req.user },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Current password and new password are required',
        },
      });
    }

    const user = await User.findById(req.user._id).select('+password');

    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'INVALID_CREDENTIALS',
          message: 'Current password is incorrect',
        },
      });
    }

    user.password = newPassword;
    user.mustChangePassword = false;
    user.tempPassword = null;
    await user.save();

    res.status(200).json({
      success: true,
      data: { message: 'Password changed successfully' },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

//  FORGOT PASSWORD 
const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'Email is required' },
      });
    }

    const user = await User.findOne({ email }).select('+otpCode +otpExpiry');
    if (!user) {
      return res.status(200).json({
        success: true,
        data: { message: 'If this email exists, an OTP has been sent' },
      });
    }

    if (user.status !== 'active') {
      return res.status(403).json({
        success: false,
        error: {
          code: 'ACCOUNT_SUSPENDED',
          message: 'Your account has been suspended. Contact admin.',
        },
      });
    }

    // Generate 6-digit OTP — this is what gets emailed, plain
    const otp       = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000);

    // Only the HASH is stored — plain OTP never touches the database
    user.otpCode   = hashToken(otp);
    user.otpExpiry = otpExpiry;
    await user.save({ validateBeforeSave: false });

    await sendEmail({
      to:      user.email,
      subject: 'SmartClass — Password Reset OTP',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
          <h2 style="color: #1a73e8;">Password Reset</h2>
          <p>Hi ${user.name},</p>
          <p>Your OTP for password reset is:</p>
          <div style="
            font-size: 36px;
            font-weight: bold;
            letter-spacing: 8px;
            color: #1a73e8;
            text-align: center;
            padding: 20px;
            background: #f0f4ff;
            border-radius: 8px;
            margin: 20px 0;
          ">${otp}</div>
          <p>This OTP expires in <strong>10 minutes</strong>.</p>
          <p>If you did not request this, ignore this email.</p>
          <hr/>
          <p style="color: #999; font-size: 12px;">SmartClass — Academic Management System</p>
        </div>
      `,
    });

    res.status(200).json({
      success: true,
      data: { message: 'OTP sent to your email' },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// VERIFY OTP 
const verifyOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Email and OTP are required',
        },
      });
    }

    const user = await User.findOne({ email }).select('+otpCode +otpExpiry');
    if (!user) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_OTP', message: 'Invalid OTP' },
      });
    }

    // Compare hash of submitted OTP against stored hash
    if (!user.otpCode || user.otpCode !== hashToken(otp)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_OTP', message: 'Invalid OTP' },
      });
    }

    if (!user.otpExpiry || user.otpExpiry < new Date()) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'OTP_EXPIRED',
          message: 'OTP has expired. Please request a new one.',
        },
      });
    }

    // Generate a short-lived reset token — this is what's returned to Flutter, plain
    const resetToken = crypto.randomBytes(32).toString('hex');

    // Only the HASH is stored — plain token never touches the database
    user.otpCode   = hashToken(resetToken); // reuse otpCode field for reset token
    user.otpExpiry = new Date(Date.now() + 15 * 60 * 1000);
    await user.save({ validateBeforeSave: false });

    res.status(200).json({
      success: true,
      data: {
        message:    'OTP verified successfully',
        resetToken, // plain token sent to Flutter — never stored plain
        email,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// RESET PASSWORD 
const resetPassword = async (req, res) => {
  try {
    const { email, resetToken, newPassword } = req.body;

    if (!email || !resetToken || !newPassword) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'email, resetToken and newPassword are required',
        },
      });
    }

    const user = await User.findOne({ email }).select(
      '+otpCode +otpExpiry +password'
    );

    if (!user) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_TOKEN', message: 'Invalid reset token' },
      });
    }

    // Compare hash of submitted token against stored hash
    if (!user.otpCode || user.otpCode !== hashToken(resetToken)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_TOKEN', message: 'Invalid reset token' },
      });
    }

    if (!user.otpExpiry || user.otpExpiry < new Date()) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'TOKEN_EXPIRED',
          message: 'Reset token has expired. Please start over.',
        },
      });
    }

    user.password  = newPassword;
    user.otpCode   = null;
    user.otpExpiry = null;
    user.mustChangePassword = false;
    await user.save();

    res.status(200).json({
      success: true,
      data: { message: 'Password reset successfully. You can now log in.' },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};
//  REGISTER FCM TOKEN
/* Called by Flutter after login and whenever Firebase issues a new
 or refreshed token. Overwrites whatever token was previously
 stored — a user is assumed to be using one device at a time for
 push purposes, which is a reasonable simplification for this
 system's scale.*/
const registerFcmToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;

    if (!fcmToken || typeof fcmToken !== 'string') {
      return res.status(400).json({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'fcmToken is required' },
      });
    }

    await User.findByIdAndUpdate(req.user._id, { fcmToken });

    res.status(200).json({
      success: true,
      data: { message: 'Push notification token registered' },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

module.exports = 
{ 
   login,
   getMe,
   changePassword,
   forgotPassword,
   verifyOtp,
   resetPassword, 
   registerFcmToken,
};