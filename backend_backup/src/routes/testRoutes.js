const express = require('express');
const { getTestMessage } = require('../controllers/testController');

const router = express.Router();

// GET /api/test
router.get('/', getTestMessage);

module.exports = router;
