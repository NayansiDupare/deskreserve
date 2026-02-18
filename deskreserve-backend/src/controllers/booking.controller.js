/**
 * ❌ BOOKING CONTROLLER (DEPRECATED)
 * DeskReserve is now SUBSCRIPTION-FIRST
 * This controller is intentionally disabled
 */

exports.createBooking = async (req, res) => {
  return res.status(410).json({
    error: 'Booking API is deprecated. Use subscription flow.',
  });
};

exports.listBookings = async (req, res) => {
  return res.status(410).json({
    error: 'Booking API is deprecated. Use subscription flow.',
  });
};

exports.cancelBooking = async (req, res) => {
  return res.status(410).json({
    error: 'Booking API is deprecated. Use subscription flow.',
  });
};

exports.availableSeats = async (req, res) => {
  return res.status(410).json({
    error: 'Booking API is deprecated. Use subscription flow.',
  });
};
