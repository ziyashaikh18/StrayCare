const jwt = require('jsonwebtoken');
const config = require('../config/env');

/**
 * Signs a JWT for a given user.
 * Payload is intentionally minimal — just enough to identify + authorize
 * the user on every request without a DB lookup for role checks.
 */
const generateToken = (user) => {
  return jwt.sign(
    {
      sub: user._id.toString(),
      role: user.role,
    },
    config.jwtSecret,
    { expiresIn: config.jwtExpiresIn }
  );
};

module.exports = generateToken;
