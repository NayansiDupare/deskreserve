const {
  getSeatStatusByDate,
  getAvailableSeats,
  
} = require('../services/sheets.service');

/**
 * 📊 Live seat status (legacy, read-only)
 */
exports.getSeatStatus = async (req, res) => {
  try {
    const { date } = req.query;
    if (!date) {
      return res.status(400).json({ error: 'date is required' });
    }

    const data = await getSeatStatusByDate(
      process.env.GOOGLE_SHEET_ID,
      date
    );

    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};


/**
 * 🪑 Seat availability for subscription flow
 */
exports.getSeatAvailability = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    if (!startDate || !endDate) {
      return res.status(400).json({
        error: 'startDate and endDate are required',
      });
    }

    const seats = await getAvailableSeats(
      process.env.GOOGLE_SHEET_ID,
      startDate,
      endDate
    );

    res.json({ availableSeats: seats });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
