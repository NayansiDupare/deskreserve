const express = require('express');
const router = express.Router();

/**
 * ❌ BOOKING ROUTES DISABLED
 * Subscription owns everything now
 */
router.use((req, res) => {
  res.status(410).json({
    error: 'Booking routes are deprecated. Use subscription APIs.',
  });
});

module.exports = router;
