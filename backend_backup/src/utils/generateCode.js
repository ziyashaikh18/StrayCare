/**
 * Generates a 6-digit numeric code, e.g. for email verification or
 * password reset. Not cryptographically sensitive — short-lived and
 * paired with an expiry, similar to a typical OTP flow.
 */
const generateCode = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

/**
 * Returns a Date `minutes` from now — used as an expiry timestamp
 * alongside a generated code.
 */
const getExpiryDate = (minutes = 10) => {
  return new Date(Date.now() + minutes * 60 * 1000);
};

module.exports = { generateCode, getExpiryDate };
