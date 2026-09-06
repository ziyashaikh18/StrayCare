const User = require('../models/User');

const listApprovedPartners = async (req, res, next) => {
  try {
    const partners = await User.find({
      role: 'ngo',
      partnerStatus: 'approved',
    })
      .select('name email phone organizationName address location createdAt updatedAt')
      .sort({ updatedAt: -1, createdAt: -1 });

    res.json({
      success: true,
      data: {
        partners: partners.map((partner) => ({
          id: partner._id,
          name: partner.name,
          email: partner.email,
          phone: partner.phone,
          organizationName: partner.organizationName,
          address: partner.address,
          location: partner.location,
          approvedAt: partner.updatedAt || partner.createdAt,
        })),
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { listApprovedPartners };
