/**
 * Controller for Test Endpoint
 * GET /api/test
 */
const getTestMessage = (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Backend is running successfully',
  });
};

module.exports = {
  getTestMessage,
};
