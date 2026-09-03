const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
    },
    phone: {
      type: String,
      trim: true,
    },
    passwordHash: {
      type: String,
      required: [true, 'Password is required'],
      select: false, // never return this field by default
    },
    role: {
      type: String,
      enum: ['reporter', 'ngo', 'admin'],
      default: 'reporter',
    },
    partnerStatus: {
      type: String,
      enum: ['pending', 'approved', 'rejected'],
    },

    // Email verification
    isEmailVerified: {
      type: Boolean,
      default: false,
    },
    emailVerificationCode: {
      type: String,
      select: false,
    },
    emailVerificationExpires: {
      type: Date,
      select: false,
    },

    // Password reset
    passwordResetCode: {
      type: String,
      select: false,
    },
    passwordResetExpires: {
      type: Date,
      select: false,
    },

    // Profile fields (personal_information_screen.dart / profile_screen.dart)
    avatarUrl: String,
    location: String,
    bio: String,
    gender: String,
    dateOfBirth: Date,
    badge: {
      type: String,
      default: 'Rescuer',
    },
    emergencyContactName: String,
    emergencyContactPhone: String,

    // Gamification (rescue_points.dart)
    points: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);
