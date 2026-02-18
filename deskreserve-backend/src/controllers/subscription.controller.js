const sheetsService = require('../services/sheets.service');
const {
  createSubscription,
  calculateSubscriptionPrice,
  addAuditLog,
  changeSeat: changeSeatService,
  createTempQuote,
  getValidQuote,
  markQuoteUsed,
  getSubscriptionDetails,
  updateSubscription,
  softDeleteSubscription,
  getActiveSubscription,
  updateSubscriptionFreeze,
  isUserFrozen,
  getAllSubscriptions,
} = sheetsService;

/* ============================================================
   💰 PRICE PREVIEW
============================================================ */

exports.quote = async (req, res) => {
  try {
    const { slots, months } = req.body;

    const price = calculateSubscriptionPrice({
      slots,
      months: Number(months),
    });

    res.json(price);

  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

/* ============================================================
   🔒 LOCK QUOTE
============================================================ */

exports.lockQuote = async (req, res) => {
  try {
    const { slots, months, discount = 0 } = req.body;

    const quote = await createTempQuote(
      process.env.GOOGLE_SHEET_ID,
      { slots, months, discount }
    );

    res.json(quote);

  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

/* ============================================================
   🔥 CREATE SUBSCRIPTION
============================================================ */

exports.create = async (req, res) => {
  try {
    const { quoteId, email, seat, payment, student } = req.body;

    const quote = await getValidQuote(
      process.env.GOOGLE_SHEET_ID,
      quoteId
    );

    if (Number(payment.paidAmount) !== Number(quote.finalAmount)) {
      throw new Error("Payment mismatch");
    }

    await createSubscription(process.env.GOOGLE_SHEET_ID, {
      email,
      seat: Number(seat),
      months: quote.months,
      slots: quote.slots,
      payment,
      student,
    });

    await markQuoteUsed(
      process.env.GOOGLE_SHEET_ID,
      quote.rowIndex
    );

    await addAuditLog(process.env.GOOGLE_SHEET_ID, {
      admin: "ADMIN_PANEL",
      action: "CREATE_SUBSCRIPTION",
      details: `Seat ${seat} assigned to ${email}`,
    });

    res.json({ success: true });

  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

/* ============================================================
   🔁 CHANGE SEAT
============================================================ */

exports.changeSeat = async (req, res) => {
  try {
    const { email, oldSeat, newSeat } = req.body;
    const sheetId = process.env.GOOGLE_SHEET_ID;

    const sub = await sheetsService.getActiveSubscription(sheetId, email);

    if (!sub) {
      return res.status(404).json({
        error: "Active subscription not found",
      });
    }

    // ❄ Prevent during freeze
    const frozen = await sheetsService.isUserFrozen(sheetId, email);
    if (frozen) {
      return res.status(400).json({
        error: "Cannot change seat during active freeze",
      });
    }

    //  1 month plan block
    if (Number(sub.months) === 1) {
      return res.status(400).json({
        error: "Seat change not allowed for 1 month plan",
      });
    }

    //  Limit check
    if (
      Number(sub.seat_change_used) >=
      Number(sub.seat_change_allowed)
    ) {
      return res.status(400).json({
        error: "Seat change limit exceeded",
      });
    }

    // ✅ Service handles seat update + increment
    const result = await sheetsService.changeSeat(sheetId, {
      email,
      oldSeat,
      newSeat,
      admin: "ADMIN_PANEL",
    });

    res.json(result);

  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};




/* ============================================================
   📄 GET FULL SUBSCRIPTION DETAILS
============================================================ */

exports.getSubscriptionDetails = async (req, res) => {
  try {
    const { email } = req.query;

    const sub = await sheetsService.getSubscriptionDetails(
      process.env.GOOGLE_SHEET_ID,
      email
    );

    if (!sub) {
      return res.status(404).json({ error: "Subscription not found" });
    }

    res.json(sub);

  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

/* ============================================================
   ✏ UPDATE SUBSCRIPTION (PARTIAL)
============================================================ */

exports.updateSubscription = async (req, res) => {
  try {
    const { email, updates } = req.body;

    await updateSubscription(
      process.env.GOOGLE_SHEET_ID,
      email,
      updates
    );

    res.json({
      success: true,
      message: "Subscription updated successfully"
    });

  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

/* ============================================================
   🗑 SOFT DELETE
============================================================ */

exports.deleteSubscription = async (req, res) => {
  try {
    const { email } = req.body;

    await softDeleteSubscription(
      process.env.GOOGLE_SHEET_ID,
      email
    );

    res.json({
      success: true,
      message: "Subscription soft deleted"
    });

  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};


exports.getAllSubscriptions = async (req, res) => {
  try {
    const sheetId = process.env.GOOGLE_SHEET_ID;

    const data = await sheetsService.getAllSubscriptions(sheetId);

    res.status(200).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
/* ============================================================
   ❄ DIRECT FREEZE
============================================================ */

exports.freezeSubscription = async (req, res) => {
  try {
    const { email, freeze_days } = req.body;

    const sub = await getActiveSubscription(
      process.env.GOOGLE_SHEET_ID,
      email
    );

    if (!sub) {
      return res.status(404).json({
        error: "Active subscription not found"
      });
    }

    if (sub.freeze_days_used + freeze_days > sub.freeze_days_allowed) {
      return res.status(400).json({
        error: "Freeze limit exceeded"
      });
    }

    const endDate = new Date(sub.end_date);
    endDate.setDate(endDate.getDate() + Number(freeze_days));

    const newEnd = endDate.toISOString().slice(0, 10);
    const newUsed = sub.freeze_days_used + Number(freeze_days);

    await updateSubscriptionFreeze(
      process.env.GOOGLE_SHEET_ID,
      sub.rowIndex,
      newEnd,
      newUsed
    );

    res.json({
      success: true,
      new_end_date: newEnd,
      freeze_days_used: newUsed
    });

  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};
