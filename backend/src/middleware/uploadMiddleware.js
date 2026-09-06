const multer = require('multer');
const path = require('path');
const fs = require('fs');

const UPLOAD_DIR = path.join(__dirname, '..', '..', 'uploads', 'reports');

// Ensure the upload directory exists.
if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

const MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024; // 5 MB

const allowedMimeTypes = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
];

const allowedExtensions = [
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
  '.heic',
  '.heif',
];

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, UPLOAD_DIR);
  },

  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase() || '.jpg';

    const uniqueName = `report_${Date.now()}_${Math.round(
      Math.random() * 1e9
    )}${ext}`;

    cb(null, uniqueName);
  },
});

const fileFilter = (req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();

  const isAllowedMimeType = allowedMimeTypes.includes(file.mimetype);
  const isAllowedExtension = allowedExtensions.includes(ext);

  if (isAllowedMimeType && isAllowedExtension) {
    return cb(null, true);
  }

  console.warn('[Upload] Rejected file:', {
    originalname: file.originalname,
    mimetype: file.mimetype,
    extension: ext,
  });

  const err = new Error(
    'Unsupported image format. Allowed formats: JPG, JPEG, PNG, WEBP, HEIC, HEIF.'
  );

  err.statusCode = 400;
  return cb(err);
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: MAX_FILE_SIZE_BYTES,
  },
});

// The multipart field name must be "image".
const uploadReportImage = upload.single('image');

/**
 * Wraps Multer's callback-style middleware so Multer errors
 * are handled by the centralized error handler.
 */
const handleReportImageUpload = (req, res, next) => {
  uploadReportImage(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        err.statusCode = 400;
        err.message = 'Image must be smaller than 5MB';
      } else {
        err.statusCode = 400;
      }

      return next(err);
    }

    if (err) {
      return next(err);
    }

    next();
  });
};

module.exports = {
  handleReportImageUpload,
};