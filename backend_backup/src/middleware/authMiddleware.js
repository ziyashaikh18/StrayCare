const jwt = require('jsonwebtoken');
const config = require('../config/env');
const User = require('../models/User');

/**
 * Verifies the `Authorization: Bearer <token>` header, loads the user,
 * and attaches it to `req.user`. Rejects with 401 if missing/invalid.
 */
const protect = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      const err = new Error('Not authorized — no token provided');
      err.statusCode = 401;
      throw err;
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, config.jwtSecret);

    const user = await User.findById(decoded.sub);
    if (!user) {
      const err = new Error('Not authorized — user no longer exists');
      err.statusCode = 401;
      throw err;
    }

    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      error.statusCode = 401;
      error.message = 'Not authorized — invalid or expired token';
    }
    next(error);
  }
};

/**
 * Restricts a route to specific roles. Use after `protect`.
 * Example: router.get('/ngo/reports', protect, requireRole('ngo', 'admin'), handler)
 */
const requireRole = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      const err = new Error('Forbidden — insufficient permissions');
      err.statusCode = 403;
      return next(err);
    }
    next();
  };
};

module.exports = { protect, requireRole };
