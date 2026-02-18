const sheetsService = require("../services/sheets.service");

/* ===============================
   🔹 REQUEST FREEZE
================================= */
exports.requestFreeze = async (req, res) => {
  try {
    const sheetId = process.env.GOOGLE_SHEET_ID;
    const { email, start_date, end_date } = req.body;

    if (!email || !start_date || !end_date) {
      return res.status(400).json({
        message: "Email, start_date and end_date required",
      });
    }

    const today = new Date().toISOString().slice(0, 10);

    if (start_date < today) {
      return res.status(400).json({
        message: "Freeze cannot be retroactive",
      });
    }

    if (end_date < start_date) {
      return res.status(400).json({
        message: "Invalid date range",
      });
    }

    const subscription = await sheetsService.getActiveSubscription(
      sheetId,
      email
    );

    if (!subscription) {
      return res.status(403).json({
        message: "No active subscription",
      });
    }

    if (start_date > subscription.end_date) {
      return res.status(400).json({
        message: "Freeze outside subscription period",
      });
    }

    const start = new Date(start_date);
    const end = new Date(end_date);

    const totalDays =
      Math.ceil((end - start) / (1000 * 60 * 60 * 24)) + 1;

    const remaining =
      subscription.freeze_days_allowed -
      subscription.freeze_days_used;

    if (totalDays > remaining) {
      return res.status(400).json({
        message: `Only ${remaining} freeze days remaining`,
      });
    }

    const overlapping = await sheetsService.checkOverlappingFreeze(
      sheetId,
      email,
      start_date,
      end_date
    );

    if (overlapping) {
      return res.status(400).json({
        message: "Overlapping freeze request exists",
      });
    }

    await sheetsService.insertFreezeRequest(sheetId, {
      freeze_id: `FRZ-${Date.now()}`,
      email,
      start_date,
      end_date,
      total_days: totalDays,
      status: "pending",
      requested_at: new Date().toISOString(),
      approved_at: "",
      approved_by: "",
      rejection_reason: "",
    });

    res.json({
      message: "Freeze request submitted successfully",
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({
      message: error.message,
    });
  }
};


/* ===============================
   🔹 APPROVE / REJECT FREEZE
================================= */
exports.approveFreeze = async (req, res) => {
  try {
    const sheetId = process.env.GOOGLE_SHEET_ID;
    const { freeze_id, action, reason } = req.body;

    if (!freeze_id || !action) {
      return res.status(400).json({
        message: "freeze_id and action required",
      });
    }

    const freeze = await sheetsService.getFreezeById(
      sheetId,
      freeze_id
    );

    if (!freeze || freeze.status !== "pending") {
      return res.status(400).json({
        message: "Invalid freeze request",
      });
    }

    if (action === "reject") {
      await sheetsService.updateFreezeStatus(
        sheetId,
        freeze.rowIndex,
        {
          status: "rejected",
          rejection_reason: reason || "Rejected by admin",
          approved_at: new Date().toISOString(),
          approved_by: "ADMIN_PANEL",
        }
      );

      return res.json({ message: "Freeze rejected" });
    }

    // 🔥 APPROVE FLOW

    const subscription = await sheetsService.getActiveSubscription(
      sheetId,
      freeze.email
    );

    if (!subscription) {
      return res.status(400).json({
        message: "Subscription not found",
      });
    }

    const remaining =
      subscription.freeze_days_allowed -
      subscription.freeze_days_used;

    if (freeze.total_days > remaining) {
      return res.status(400).json({
        message: "Insufficient freeze balance",
      });
    }

    const oldEnd = new Date(subscription.end_date);
    oldEnd.setDate(oldEnd.getDate() + freeze.total_days);

    const newEndDate = oldEnd.toISOString().slice(0, 10);

    await sheetsService.updateSubscriptionFreeze(
      sheetId,
      subscription.rowIndex,
      newEndDate,
      subscription.freeze_days_used + freeze.total_days
    );

    await sheetsService.updateFreezeStatus(
      sheetId,
      freeze.rowIndex,
      {
        status: "approved",
        approved_at: new Date().toISOString(),
        approved_by: "ADMIN_PANEL",
      }
    );

    res.json({
      message: "Freeze approved successfully",
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({
      message: error.message,
    });
  }
};


/* ===============================
   🔹 GET FREEZE STATUS
================================= */
exports.getMyFreezeStatus = async (req, res) => {
  try {
    const sheetId = process.env.GOOGLE_SHEET_ID;
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        message: "Email required",
      });
    }

    const subscription = await sheetsService.getActiveSubscription(
      sheetId,
      email
    );

    if (!subscription) {
      return res.status(404).json({
        message: "No active subscription found",
      });
    }

    const freezeRes = await sheetsService.getAllFreezesByEmail(
      sheetId,
      email
    );

    const today = new Date().toISOString().slice(0, 10);

    let activeFreeze = null;

    for (const freeze of freezeRes) {
      if (
        freeze.status === "approved" &&
        today >= freeze.start_date &&
        today <= freeze.end_date
      ) {
        activeFreeze = freeze;
        break;
      }
    }

    const remaining =
      subscription.freeze_days_allowed -
      subscription.freeze_days_used;

    res.json({
      isFrozen: !!activeFreeze,
      freezeStart: activeFreeze?.start_date || null,
      freezeEnd: activeFreeze?.end_date || null,
      freezeDaysUsed: subscription.freeze_days_used,
      freezeDaysRemaining: remaining,
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({
      message: error.message,
    });
  }
};


/* ===============================
   🔹 GET PENDING FREEZES
================================= */
exports.getPendingFreezes = async (req, res) => {
  try {
    const sheetId = process.env.GOOGLE_SHEET_ID;

    const pending = await sheetsService.getPendingFreezes(sheetId);

    res.json(pending);

  } catch (error) {
    console.error(error);
    res.status(500).json({
      message: error.message,
    });
  }
};
