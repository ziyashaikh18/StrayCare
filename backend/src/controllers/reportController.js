const fs = require('fs');
const path = require('path');
const Report = require('../models/Report');
const createNotification = require('../utils/createNotification');

const SEVERITY_LEVELS = ['Low', 'Medium', 'High', 'Critical'];
const VALID_STATUSES = ['new', 'assigned', 'inReview', 'resolved'];

const STATUS_ORDER = {
  new: 0,
  assigned: 1,
  inReview: 2,
  resolved: 3,
};

/**
 * Builds the public URL for an uploaded image based on the request host,
 * so the frontend gets a directly-usable link regardless of environment.
 * e.g. http://10.0.2.2:5000/uploads/reports/report_123.jpg
 */
const buildImageUrl = (req, filename) => {
  return `${req.protocol}://${req.get('host')}/uploads/reports/${filename}`;
};

const toReportResponse = (report) => ({
  id: report._id,
  _id: report._id,
  user: report.user,
  reporterId: report.user?._id || report.user,
  reporter:
    report.user && typeof report.user === 'object' && report.user.name
      ? {
          id: report.user._id,
          name: report.user.name,
          email: report.user.email,
          phone: report.user.phone,
        }
      : undefined,
  imageUrl: report.imageUrl,
  animalType: report.animalType,
  injuryType: report.injuryType,
  severity: report.severity,
  description: report.description,
  location: report.location,
  latitude: report.latitude,
  longitude: report.longitude,
  status: report.status,
  assignedNgo: report.assignedNgo || null,
  assignedAt: report.assignedAt,
  inReviewAt: report.inReviewAt,
  resolvedAt: report.resolvedAt,
  timeline: report.timeline || [],
  createdAt: report.createdAt,
  updatedAt: report.updatedAt,
});

// POST /api/reports  (protected, multipart/form-data)
const createReport = async (req, res, next) => {
  try {
    const { animalType, injuryType, severity, description, location, latitude, longitude } =
      req.body;

    // --- Validation ---
    if (!req.file) {
      const err = new Error('An image of the animal is required');
      err.statusCode = 400;
      throw err;
    }
    if (!animalType || !animalType.trim()) {
      const err = new Error('animalType is required');
      err.statusCode = 400;
      throw err;
    }
    if (!injuryType || !injuryType.trim()) {
      const err = new Error('injuryType is required');
      err.statusCode = 400;
      throw err;
    }
    if (!severity || !SEVERITY_LEVELS.includes(severity)) {
      const err = new Error(`severity is required and must be one of: ${SEVERITY_LEVELS.join(', ')}`);
      err.statusCode = 400;
      throw err;
    }
    if (description && description.length > 1000) {
      const err = new Error('description cannot exceed 1000 characters');
      err.statusCode = 400;
      throw err;
    }

    let lat, lng;
    if (latitude !== undefined && latitude !== '') {
      lat = Number(latitude);
      if (Number.isNaN(lat) || lat < -90 || lat > 90) {
        const err = new Error('latitude must be a valid number between -90 and 90');
        err.statusCode = 400;
        throw err;
      }
    }
    if (longitude !== undefined && longitude !== '') {
      lng = Number(longitude);
      if (Number.isNaN(lng) || lng < -180 || lng > 180) {
        const err = new Error('longitude must be a valid number between -180 and 180');
        err.statusCode = 400;
        throw err;
      }
    }

    const report = await Report.create({
      user: req.user._id,
      imageUrl: buildImageUrl(req, req.file.filename),
      animalType: animalType.trim(),
      injuryType: injuryType.trim(),
      severity,
      description: description ? description.trim() : undefined,
      location: location ? location.trim() : undefined,
      latitude: lat,
      longitude: lng,
      status: 'new',
      timeline: [
        {
          status: 'new',
          message: 'Rescue report submitted',
          timestamp: new Date(),
          performedBy: {
            id: req.user._id,
            name: req.user.name,
            role: req.user.role,
          },
        },
      ],
    });

    res.status(201).json({
      success: true,
      message: 'Report submitted successfully',
      data: { report: toReportResponse(report) },
    });
  } catch (error) {
    // If validation failed after multer already saved the file, clean it up
    if (req.file) {
      fs.unlink(req.file.path, () => {});
    }
    next(error);
  }
};

// GET /api/reports/admin/all (protected — NGO or Admin only)
const getAllReports = async (req, res, next) => {
  try {
    const { status, severity } = req.query;
    const filter = {};
    if (status) filter.status = status;
    if (severity) filter.severity = severity;

    const reports = await Report.find(filter)
      .populate('user', 'name email phone avatarUrl')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: reports.length,
      data: { reports: reports.map(toReportResponse) },
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/reports/my & GET /api/reports (protected — current user's own reports)
const getMyReports = async (req, res, next) => {
  try {
    const { status } = req.query;
    const filter = { user: req.user._id };
    if (status) filter.status = status;

    const reports = await Report.find(filter)
      .populate('user', 'name email phone avatarUrl')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: reports.length,
      data: { reports: reports.map(toReportResponse) },
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/reports/:id  (protected — owner, NGO, or admin)
const getReportById = async (req, res, next) => {
  try {
    const report = await Report.findById(req.params.id).populate('user', 'name email phone avatarUrl');

    if (!report) {
      const err = new Error('Report not found');
      err.statusCode = 404;
      throw err;
    }
    if (
      report.user.toString() !== req.user._id.toString() &&
      req.user.role === 'reporter'
    ) {
      const err = new Error('You do not have permission to view this report');
      err.statusCode = 403;
      throw err;
    }

    res.status(200).json({ success: true, data: { report: toReportResponse(report) } });
  } catch (error) {
    next(error);
  }
};

// PATCH /api/reports/:id/assign (protected — NGO or Admin only)
const assignReport = async (req, res, next) => {
  try {
    const report = await Report.findById(req.params.id);

    if (!report) {
      const err = new Error('Report not found');
      err.statusCode = 404;
      throw err;
    }

    // Restrict assignment if already assigned
    if (report.assignedNgo && report.assignedNgo.id) {
      const err = new Error(
        `This case has already been assigned to ${report.assignedNgo.name || 'another NGO'}`
      );
      err.statusCode = 400;
      throw err;
    }

    report.assignedNgo = {
      id: req.user._id,
      name: req.user.name,
      email: req.user.email,
      phone: req.user.phone || undefined,
    };
    report.status = 'assigned';
    report.assignedAt = new Date();
    report.updatedAt = new Date();

    if (!report.timeline) report.timeline = [];
    report.timeline.push({
      status: 'assigned',
      message: `Case assigned to ${req.user.name}`,
      timestamp: new Date(),
      performedBy: {
        id: req.user._id,
        name: req.user.name,
        role: req.user.role,
      },
    });

    await report.save();

    try {
      await createNotification({
        user: report.user,
        type: 'report_assigned',
        title: 'Report Assigned',
        message: `Your report has been assigned to ${req.user.name}.`,
        relatedReport: report._id,
      });
    } catch (notificationError) {
      console.error('Failed to create assignment notification:', notificationError.message);
    }

    res.status(200).json({
      success: true,
      message: 'Report assigned successfully',
      data: { report: toReportResponse(report) },
    });
  } catch (error) {
    next(error);
  }
};

// PATCH /api/reports/:id/status (protected — NGO or Admin only)
const updateReportStatus = async (req, res, next) => {
  try {
    const { status } = req.body;

    if (!status || !VALID_STATUSES.includes(status)) {
      const err = new Error(
        `Invalid status. Allowed statuses: ${VALID_STATUSES.join(', ')}`
      );
      err.statusCode = 400;
      throw err;
    }

    const report = await Report.findById(req.params.id);
    if (!report) {
      const err = new Error('Report not found');
      err.statusCode = 404;
      throw err;
    }

    const currentOrder = STATUS_ORDER[report.status] ?? 0;
    const newOrder = STATUS_ORDER[status] ?? 0;

    if (report.status === status) {
      return res.status(200).json({
        success: true,
        message: 'Report status is already up to date',
        data: { report: toReportResponse(report) },
      });
    }

    // Enforce forward-only progression
    if (newOrder < currentOrder) {
      const err = new Error(
        `Cannot move status backward from "${report.status}" to "${status}". Progression must be: new → assigned → inReview → resolved.`
      );
      err.statusCode = 400;
      throw err;
    }

    report.status = status;
    report.updatedAt = new Date();

    let timelineMessage = `Case status updated to ${status}`;

    if (status === 'assigned') {
      if (!report.assignedAt) report.assignedAt = new Date();
      timelineMessage = `Case marked as assigned`;
    } else if (status === 'inReview') {
      if (!report.inReviewAt) report.inReviewAt = new Date();
      timelineMessage = `Case is under active review and rescue team is deployed`;
    } else if (status === 'resolved') {
      if (!report.resolvedAt) report.resolvedAt = new Date();
      timelineMessage = `Rescue case has been resolved`;
    }

    if (!report.timeline) report.timeline = [];
    report.timeline.push({
      status,
      message: timelineMessage,
      timestamp: new Date(),
      performedBy: {
        id: req.user._id,
        name: req.user.name,
        role: req.user.role,
      },
    });

    await report.save();

    try {
      await createNotification({
        user: report.user,
        type: 'report_status_changed',
        title: 'Report Status Updated',
        message: `Your report status changed to ${status}.`,
        relatedReport: report._id,
      });
    } catch (notificationError) {
      console.error('Failed to create status notification:', notificationError.message);
    }

    res.status(200).json({
      success: true,
      message: 'Report status updated successfully',
      data: { report: toReportResponse(report) },
    });
  } catch (error) {
    next(error);
  }
};

// PUT /api/reports/:id  (protected — owner only, no image/ownership change)
const updateReport = async (req, res, next) => {
  try {
    const report = await Report.findById(req.params.id);

    if (!report) {
      const err = new Error('Report not found');
      err.statusCode = 404;
      throw err;
    }
    if (report.user.toString() !== req.user._id.toString()) {
      const err = new Error('You do not have permission to edit this report');
      err.statusCode = 403;
      throw err;
    }

    const { animalType, injuryType, severity, description, location } = req.body;

    if (animalType !== undefined) {
      if (!animalType.trim()) {
        const err = new Error('animalType cannot be empty');
        err.statusCode = 400;
        throw err;
      }
      report.animalType = animalType.trim();
    }
    if (injuryType !== undefined) {
      if (!injuryType.trim()) {
        const err = new Error('injuryType cannot be empty');
        err.statusCode = 400;
        throw err;
      }
      report.injuryType = injuryType.trim();
    }
    if (severity !== undefined) {
      if (!SEVERITY_LEVELS.includes(severity)) {
        const err = new Error(`severity must be one of: ${SEVERITY_LEVELS.join(', ')}`);
        err.statusCode = 400;
        throw err;
      }
      report.severity = severity;
    }
    if (description !== undefined) {
      if (description.length > 1000) {
        const err = new Error('description cannot exceed 1000 characters');
        err.statusCode = 400;
        throw err;
      }
      report.description = description.trim();
    }
    if (location !== undefined) {
      report.location = location.trim();
    }

    await report.save();

    res.status(200).json({
      success: true,
      message: 'Report updated successfully',
      data: { report: toReportResponse(report) },
    });
  } catch (error) {
    next(error);
  }
};

// DELETE /api/reports/:id  (protected — owner only)
const deleteReport = async (req, res, next) => {
  try {
    const report = await Report.findById(req.params.id);

    if (!report) {
      const err = new Error('Report not found');
      err.statusCode = 404;
      throw err;
    }
    if (report.user.toString() !== req.user._id.toString()) {
      const err = new Error('You do not have permission to delete this report');
      err.statusCode = 403;
      throw err;
    }

    if (report.imageUrl) {
      const filename = report.imageUrl.split('/uploads/reports/')[1];
      if (filename) {
        const filePath = path.join(__dirname, '..', '..', 'uploads', 'reports', filename);
        fs.unlink(filePath, () => {});
      }
    }

    await report.deleteOne();

    res.status(200).json({ success: true, message: 'Report deleted successfully' });
  } catch (error) {
    next(error);
  }
};

// GET /api/reports/nearby  (protected — geospatial search for nearby reports)
const getNearbyReports = async (req, res, next) => {
  try {
    const { lat, lng, radiusKm, status, severity } = req.query;

    if (lat === undefined || lat === '') {
      const err = new Error('lat is required');
      err.statusCode = 400;
      throw err;
    }
    const latitude = Number(lat);
    if (Number.isNaN(latitude) || latitude < -90 || latitude > 90) {
      const err = new Error('lat must be a valid number between -90 and 90');
      err.statusCode = 400;
      throw err;
    }

    if (lng === undefined || lng === '') {
      const err = new Error('lng is required');
      err.statusCode = 400;
      throw err;
    }
    const longitude = Number(lng);
    if (Number.isNaN(longitude) || longitude < -180 || longitude > 180) {
      const err = new Error('lng must be a valid number between -180 and 180');
      err.statusCode = 400;
      throw err;
    }

    let radius = 5;
    if (radiusKm !== undefined && radiusKm !== '') {
      radius = Number(radiusKm);
      if (Number.isNaN(radius) || radius <= 0) {
        const err = new Error('radiusKm must be a positive number');
        err.statusCode = 400;
        throw err;
      }
    }

    const filter = {
      geo: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [longitude, latitude],
          },
          $maxDistance: radius * 1000,
        },
      },
    };

    if (status) {
      filter.status = status;
    }
    if (severity) {
      filter.severity = severity;
    }

    const reports = await Report.find(filter);

    res.status(200).json({
      success: true,
      count: reports.length,
      data: { reports: reports.map(toReportResponse) },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createReport,
  getAllReports,
  getMyReports,
  getNearbyReports,
  getReportById,
  assignReport,
  updateReportStatus,
  updateReport,
  deleteReport,
};