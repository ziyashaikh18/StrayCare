const PartnerRequest = require('../models/PartnerRequest');
const User = require('../models/User');

const toResponse = (request) => ({
  id: request._id,
  user: request.user,
  organizationName: request.organizationName,
  contactPerson: request.contactPerson,
  email: request.email,
  phone: request.phone,
  address: request.address,
  website: request.website,
  animalsSupported: request.animalsSupported,
  emergencyRescue: request.emergencyRescue,
  status: request.status,
  createdAt: request.createdAt,
  reviewedAt: request.reviewedAt,
  rejectionReason: request.rejectionReason,
});

const createRequest = async (req, res, next) => {
  try {
    if (req.user.role !== 'reporter') {
      const error = new Error('Only reporter accounts can apply as rescue partners');
      error.statusCode = 403;
      throw error;
    }

    const request = await PartnerRequest.create({
      user: req.user._id,
      organizationName: req.body.organizationName,
      contactPerson: req.body.contactPerson,
      email: req.body.email,
      phone: req.body.phone,
      address: req.body.address,
      website: req.body.website,
      animalsSupported: req.body.animalsSupported,
      emergencyRescue: Boolean(req.body.emergencyRescue),
    });

    await User.findByIdAndUpdate(req.user._id, { partnerStatus: 'pending' });
    res.status(201).json({ success: true, data: { request: toResponse(request) } });
  } catch (error) {
    next(error);
  }
};

const getMyStatus = async (req, res, next) => {
  try {
    const request = await PartnerRequest.findOne({ user: req.user._id })
      .sort({ createdAt: -1 });

    if (!request) {
      return res.json({ success: true, data: { request: null } });
    }

    res.json({
      success: true,
      data: {
        request: {
          id: request._id,
          organizationName: request.organizationName,
          status: request.status,
          rejectionReason: request.rejectionReason ?? null,
          createdAt: request.createdAt,
          updatedAt: request.updatedAt,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

const listRequests = async (req, res, next) => {
  try {
    const filter = req.query.status ? { status: req.query.status } : {};
    const requests = await PartnerRequest.find(filter)
      .populate('user', 'name email phone role')
      .sort({ createdAt: -1 });
    res.json({ success: true, count: requests.length, data: { requests: requests.map(toResponse) } });
  } catch (error) {
    next(error);
  }
};

const reviewRequest = (status) => async (req, res, next) => {
  try {
    const request = await PartnerRequest.findById(req.params.id);
    if (!request) {
      const error = new Error('Partner request not found');
      error.statusCode = 404;
      throw error;
    }

    request.status = status;
    request.reviewedAt = new Date();
    request.reviewedBy = req.user._id;
    if (status === 'rejected') request.rejectionReason = req.body.rejectionReason;
    await request.save();

    await User.findByIdAndUpdate(request.user, {
      role: status === 'approved' ? 'ngo' : 'reporter',
      partnerStatus: status,
      ...(status === 'approved'
        ? {
            organizationName: request.organizationName,
            phone: request.phone,
            address: request.address,
          }
        : {}),
    });

    res.json({ success: true, data: { request: toResponse(request) } });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createRequest,
  getMyStatus,
  listRequests,
  approveRequest: reviewRequest('approved'),
  rejectRequest: reviewRequest('rejected'),
};
