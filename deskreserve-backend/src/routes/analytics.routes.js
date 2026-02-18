const express = require('express');
const router = express.Router();

const auth = require('../middlewares/auth.middleware');
const {
  todaySummary,
  revenueSummary,
  seatUtilization,
} = require('../controllers/analytics.controller');

router.get('/today', auth, todaySummary);
router.get('/revenue', auth, revenueSummary);
router.get('/seats', auth, seatUtilization);

module.exports = router;
