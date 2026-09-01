const bcrypt = require('bcryptjs');
const User = require('../models/User');
const generateToken = require('../utils/generateToken');
const { generateCode, getExpiryDate } = require('../utils/generateCode');

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const SALT_ROUNDS = 10;

/**
 * Shape a user document for API responses — never leak passwordHash
 * or verification/reset codes, even though those fields already have
 * `select: false` on the schema as a second line of defense.
 */
const toPublicUser = (user) => ({
  id: user._id,
  name: user.name,
  email: user.email,
  phone: user.phone,
  role: user.role,
  isEmailVerified: user.isEmailVerified,
  avatarUrl: user.avatarUrl,
  location: user.location,
  bio: user.bio,
  gender: user.gender,
  dateOfBirth: user.dateOfBirth,
  badge: user.badge,
  emergencyContactName: user.emergencyContactName,
  emergencyContactPhone: user.emergencyContactPhone,
  points: user.points,
  createdAt: user.createdAt,
});

// POST /api/auth/register
const register = async (req, res, next) => {
  try {
    const { name, email, phone, password } = req.body;

    if (!name || !email || !password) {
      const err = new Error('name, email and password are required');
      err.statusCode = 400;
      throw err;
    }
    if (!EMAIL_REGEX.test(email)) {
      const err = new Error('Please provide a valid email address');
      err.statusCode = 400;
      throw err;
    }
    if (password.length < 6) {
      const err = new Error('Password must be at least 6 characters');
      err.statusCode = 400;
      throw err;
    }

    const existing = await User.findOne({ email: email.toLowerCase() });
    if (existing) {
      const err = new Error('An account with this email already exists');
      err.statusCode = 409;
      throw err;
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
    const verificationCode = generateCode();

    const user = await User.create({
      name,
      email: email.toLowerCase(),
      phone,
      passwordHash,
      emailVerificationCode: verificationCode,
      emailVerificationExpires: getExpiryDate(10),
    });

    // TODO: send `verificationCode` by email/SMS once you wire up a mail
    // service. For now it's logged so you can test verify-email locally.
    console.log(`📧 Verification code for ${user.email}: ${verificationCode}`);

    res.status(201).json({
      success: true,
      message: 'Registered successfully. Check your email for a verification code.',
      data: { user: toPublicUser(user) },
    });
  } catch (error) {
    next(error);
  }
};

// POST /api/auth/verify-email
const verifyEmail = async (req, res, next) => {
  try {
    const { email, code } = req.body;

    if (!email || !code) {
      const err = new Error('email and code are required');
      err.statusCode = 400;
      throw err;
    }

    const user = await User.findOne({ email: email.toLowerCase() }).select(
      '+emailVerificationCode +emailVerificationExpires'
    );

    if (!user) {
      const err = new Error('No account found with this email');
      err.statusCode = 404;
      throw err;
    }

    if (user.isEmailVerified) {
      return res.status(200).json({
        success: true,
        message: 'Email already verified',
        data: { token: generateToken(user), user: toPublicUser(user) },
      });
    }

    if (
      !user.emailVerificationCode ||
      user.emailVerificationCode !== code ||
      !user.emailVerificationExpires ||
      user.emailVerificationExpires < new Date()
    ) {
      const err = new Error('Invalid or expired verification code');
      err.statusCode = 400;
      throw err;
    }

    user.isEmailVerified = true;
    user.emailVerificationCode = undefined;
    user.emailVerificationExpires = undefined;
    await user.save();

    res.status(200).json({
      success: true,
      message: 'Email verified successfully',
      data: { token: generateToken(user), user: toPublicUser(user) },
    });
  } catch (error) {
    next(error);
  }
};

// POST /api/auth/resend-verification
const resendVerification = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) {
      const err = new Error('email is required');
      err.statusCode = 400;
      throw err;
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      const err = new Error('No account found with this email');
      err.statusCode = 404;
      throw err;
    }
    if (user.isEmailVerified) {
      return res.status(200).json({ success: true, message: 'Email already verified' });
    }

    const verificationCode = generateCode();
    user.emailVerificationCode = verificationCode;
    user.emailVerificationExpires = getExpiryDate(10);
    await user.save();

    console.log(`📧 New verification code for ${user.email}: ${verificationCode}`);

    res.status(200).json({ success: true, message: 'Verification code resent' });
  } catch (error) {
    next(error);
  }
};

// POST /api/auth/login
const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      const err = new Error('email and password are required');
      err.statusCode = 400;
      throw err;
    }

    const user = await User.findOne({ email: email.toLowerCase() }).select('+passwordHash');
    if (!user) {
      const err = new Error('Invalid email or password');
      err.statusCode = 401;
      throw err;
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      const err = new Error('Invalid email or password');
      err.statusCode = 401;
      throw err;
    }

    res.status(200).json({
      success: true,
      message: 'Logged in successfully',
      data: { token: generateToken(user), user: toPublicUser(user) },
    });
  } catch (error) {
    next(error);
  }
};

// POST /api/auth/forgot-password
const forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) {
      const err = new Error('email is required');
      err.statusCode = 400;
      throw err;
    }

    const user = await User.findOne({ email: email.toLowerCase() });

    // Always respond success even if the user doesn't exist, so this
    // endpoint can't be used to check which emails are registered.
    if (!user) {
      return res.status(200).json({
        success: true,
        message: 'If that email is registered, a reset code has been sent',
      });
    }

    const resetCode = generateCode();
    user.passwordResetCode = resetCode;
    user.passwordResetExpires = getExpiryDate(10);
    await user.save();

    console.log(`🔑 Password reset code for ${user.email}: ${resetCode}`);

    res.status(200).json({
      success: true,
      message: 'If that email is registered, a reset code has been sent',
    });
  } catch (error) {
    next(error);
  }
};

// POST /api/auth/reset-password
const resetPassword = async (req, res, next) => {
  try {
    const { email, code, newPassword } = req.body;

    if (!email || !code || !newPassword) {
      const err = new Error('email, code and newPassword are required');
      err.statusCode = 400;
      throw err;
    }
    if (newPassword.length < 6) {
      const err = new Error('Password must be at least 6 characters');
      err.statusCode = 400;
      throw err;
    }

    const user = await User.findOne({ email: email.toLowerCase() }).select(
      '+passwordResetCode +passwordResetExpires'
    );

    if (
      !user ||
      !user.passwordResetCode ||
      user.passwordResetCode !== code ||
      !user.passwordResetExpires ||
      user.passwordResetExpires < new Date()
    ) {
      const err = new Error('Invalid or expired reset code');
      err.statusCode = 400;
      throw err;
    }

    user.passwordHash = await bcrypt.hash(newPassword, SALT_ROUNDS);
    user.passwordResetCode = undefined;
    user.passwordResetExpires = undefined;
    await user.save();

    res.status(200).json({
      success: true,
      message: 'Password reset successfully. Please log in with your new password.',
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/auth/me  (protected)
const getMe = async (req, res, next) => {
  try {
    res.status(200).json({
      success: true,
      data: { user: toPublicUser(req.user) },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  verifyEmail,
  resendVerification,
  login,
  forgotPassword,
  resetPassword,
  getMe,
};
