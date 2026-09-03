const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'A report must belong to a user'],
    },

    // Image (Multer-uploaded file, stored locally under uploads/reports/)
    imageUrl: {
      type: String,
      required: [true, 'A photo of the animal is required'],
    },

    // Core report fields — match the frontend's report_screen.dart cards
    animalType: {
      type: String,
      required: [true, 'Animal type is required'],
      trim: true,
    },
    injuryType: {
      type: String,
      required: [true, 'Injury/condition type is required'],
      trim: true,
    },
    severity: {
      type: String,
      required: [true, 'Severity is required'],
      enum: ['Low', 'Medium', 'High', 'Critical'],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [1000, 'Description cannot exceed 1000 characters'],
    },

    // Location — both the human-readable address AND raw coordinates are
    // stored, since Flutter reverse-geocodes on-device but the backend
    // needs the coordinates for nearby-case queries / duplicate detection.
    location: {
      type: String,
      trim: true,
    },
    latitude: {
      type: Number,
      min: -90,
      max: 90,
    },
    longitude: {
      type: Number,
      min: -180,
      max: 180,
    },
    // GeoJSON mirror of latitude/longitude, kept in sync in the controller,
    // required for MongoDB's $near / 2dsphere geo queries later
    // (used by GET /api/reports/nearby).
    geo: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        default: undefined,
      },
    },

    status: {
      type: String,
      enum: ['new', 'assigned', 'inReview', 'resolved'],
      default: 'new',
    },

    assignedNgo: {
      id: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
      name: { type: String },
      email: { type: String },
      phone: { type: String },
    },

    assignedAt: {
      type: Date,
    },
    inReviewAt: {
      type: Date,
    },
    resolvedAt: {
      type: Date,
    },

    timeline: [
      {
        status: {
          type: String,
          enum: ['new', 'assigned', 'inReview', 'resolved'],
        },
        message: {
          type: String,
          required: true,
        },
        timestamp: {
          type: Date,
          default: Date.now,
        },
        performedBy: {
          id: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
          },
          name: { type: String },
          role: { type: String },
        },
      },
    ],
  },
  { timestamps: true }
);

reportSchema.index({ geo: '2dsphere' });
reportSchema.index({ user: 1, createdAt: -1 });

// Keep `geo` in sync whenever latitude/longitude are set or changed.
// Keep geo in sync whenever latitude/longitude are set or changed.
reportSchema.pre('save', function () {
  if (this.latitude != null && this.longitude != null) {
    this.geo = {
      type: 'Point',
      coordinates: [this.longitude, this.latitude],
    };
  }
});

module.exports = mongoose.model('Report', reportSchema);