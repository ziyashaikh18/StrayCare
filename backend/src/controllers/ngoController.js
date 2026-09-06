const User = require('../models/User');

const removePartnership = async (req, res, next) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.user._id,
      {
        $set: {
          role: 'reporter',
          partnerStatus: 'none',
          organizationName: null,
        },
      },
      { new: true, runValidators: true }
    );

    if (!user) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }

    res.json({
      success: true,
      message: 'NGO partnership removed successfully.',
      role: user.role,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { removePartnership };
