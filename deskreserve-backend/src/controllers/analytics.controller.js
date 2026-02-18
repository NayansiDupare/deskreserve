const { getAllSubscriptions } = require('../services/sheets.service');

/**
 * 📊 TODAY SUMMARY
 */
exports.todaySummary = async (req, res) => {
  try {
    const today = new Date();

    const subs = await getAllSubscriptions(
      process.env.GOOGLE_SHEET_ID
    );

    const activeToday = subs.filter(sub => {
      const start = new Date(sub.startDate);
      const end = new Date(sub.endDate);
      return sub.status === 'ACTIVE' && start <= today && end >= today;
    });

    const occupiedSeats = activeToday.length;
    const totalSeats = 75;

    res.json({
      activeSubscriptions: activeToday.length,
      occupiedSeats,
      freeSeats: totalSeats - occupiedSeats,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

/**
 * 💰 REVENUE SUMMARY (MONTH)
 */
exports.revenueSummary = async (req, res) => {
  try {
    const { month } = req.query; // YYYY-MM

    if (!month) {
      return res.status(400).json({
        error: 'month is required (YYYY-MM)',
      });
    }

    const subs = await getAllSubscriptions(
      process.env.GOOGLE_SHEET_ID
    );

    let totalRevenue = 0;
    let totalPaid = 0;

    const filtered = subs.filter(sub =>
      sub.startDate.startsWith(month)
    );

    for (const sub of filtered) {
      totalRevenue += sub.finalAmount;
      totalPaid += sub.paidAmount;
    }

    res.json({
      month,
      subscriptions: filtered.length,
      totalRevenue,
      totalPaid,
      pendingAmount: totalRevenue - totalPaid,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

/**
 * 🪑 SEAT UTILIZATION
 */
exports.seatUtilization = async (req, res) => {
  try {
    const today = new Date();
    const subs = await getAllSubscriptions(
      process.env.GOOGLE_SHEET_ID
    );

    const activeSeats = new Set();

    subs.forEach(sub => {
      const start = new Date(sub.startDate);
      const end = new Date(sub.endDate);
      if (sub.status === 'ACTIVE' && start <= today && end >= today) {
        activeSeats.add(sub.seat);
      }
    });

    const totalSeats = 75;

    res.json({
      totalSeats,
      activeSeats: activeSeats.size,
      utilizationPercent: Math.round(
        (activeSeats.size / totalSeats) * 100
      ),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
