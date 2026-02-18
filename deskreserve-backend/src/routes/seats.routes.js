const express = require('express');
const router = express.Router();

const auth = require('../middlewares/auth.middleware');
const {
  getSeatStatus,
  getSeatAvailability,
} = require('../controllers/seats.controller');

router.get('/status', auth, getSeatStatus);
router.get('/availability', auth, getSeatAvailability);

module.exports = router;
