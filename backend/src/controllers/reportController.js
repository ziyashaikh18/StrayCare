const fs = require('fs');
const path = require('path');
const Report = require('../models/Report');

const SEVERITY_LEVELS = ['Low', 'Medium', 'High', 'Critical'];

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
  user: report.user,
  imageUrl: report.imageUrl,
  animalType: report.animalType,
  injuryType: report.injuryType,
  severity: report.severity,
  description: report.description,
  location: report.location,
  latitude: report.latitude,
  longitude: report.longitude,
  status: report.status,
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
    });

    res.status(201).json({
      success: true,
      message: 'Report submitted successfully',
      data: { report: toReportResponse(report) },
    });
  } catch (error) {
    // If validation failed after multer already saved the file, clean it up
    // so orphaned images don't pile up on disk.
    if (req.file) {
      fs.unlink(req.file.path, () => {});
    }
    next(error);
  }
};

// GET /api/reports  (protected — current user's own reports)
const getMyReports = async (req, res, next) => {
  try {
    const { status } = req.query;
    const filter = { user: req.user._id };
    if (status) filter.status = status;

    const reports = await Report.find(filter).sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: reports.length,
      data: { reports: reports.map(toReportResponse) },
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/reports/:id  (protected — owner only)
const getReportById = async (req, res, next) => {
  try {
    const report = await Report.findById(req.params.id);

    if (!report) {
      const err = new Error('Report not found');
      err.statusCode = 404;
      throw err;
    }
    if (report.user.toString() !== req.user._id.toString() && req.user.role === 'reporter') {
      const err = new Error('You do not have permission to view this report');
      err.statusCode = 403;
      throw err;
    }

    res.status(200).json({ success: true, data: { report: toReportResponse(report) } });
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

    // Best-effort cleanup of the stored image file.
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

module.exports = {
  createReport,
  getMyReports,
  getReportById,
  updateReport,
  deleteReport,
};