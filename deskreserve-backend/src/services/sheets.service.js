const sheets = require('../config/google');

const SUBSCRIPTION_SHEET = 'Subscriptions';
const TEMP_QUOTE_SHEET = 'TempQuotes';
const AUDIT_SHEET = 'AuditLogs';
const SEAT_CHANGE_SHEET = 'SeatChanges';
const FREEZE_SHEET = 'FreezeRequests';

async function findAdminByEmail(sheetId, email) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
    range: 'Admins!A:C',
  });

  const rows = res.data.values || [];
  if (rows.length <= 1) return null;

  for (const row of rows.slice(1)) {
    if (row[0] === email) {
      return {
        email: row[0],
        password_hash: row[1],
        role: row[2],
      };
    }
  }
  return null;
}

async function addAdmin(sheetId, data) {
  await sheets.spreadsheets.values.append({
    spreadsheetId: sheetId,
    range: 'Admins!A:C',
    valueInputOption: 'USER_ENTERED',
    requestBody: {
      values: [[data.email, data.password, data.role || 'STAFF']],
    },
  });
}

async function getAllStudents(sheetId) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
    range: `${SUBSCRIPTION_SHEET}!A:U`,

  });

  const rows = res.data.values || [];
  if (rows.length <= 1) return [];

  return rows.slice(1).map(r => ({
    email: r[0],
    seat: Number(r[1]),
    name: r[14],
    phone: r[15],
    idProofType: r[16],
    idProofUrl: r[17],
  }));
}

/**
 * 👤 Get single student
 */
async function getStudent(sheetId, { email, seat }) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
      range: `${SUBSCRIPTION_SHEET}!A:U`,

  });

  const rows = res.data.values || [];

  for (const r of rows.slice(1)) {
    if ((email && r[0] === email) || (seat && Number(r[1]) === Number(seat))) {
      return {
        email: r[0],
        seat: Number(r[1]),
        name: r[14],
        phone: r[15],
        idProofType: r[16],
        idProofUrl: r[17],
      };
    }
  }
  return null;
}

async function getSeatStatusByDate(sheetId, date) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
      range: `${SUBSCRIPTION_SHEET}!A:U`,
  });

  const rows = res.data.values || [];

  const DEFAULT_SLOTS = {
    "08:00-14:00": "FREE",
    "14:00-20:00": "FREE",
    "20:00-24:00": "FREE",
  };

  function toMinutes(t) {
    const [h, m] = t.split(':').map(Number);
    return h * 60 + m;
  }

  const result = [];

  for (let seat = 1; seat <= 75; seat++) {
    const slots = JSON.parse(JSON.stringify(DEFAULT_SLOTS));

   const seatSubs = rows.slice(1).filter(r => {
  if (r[5] !== 'ACTIVE') return false;
  if (Number(r[1]) !== seat) return false;

  const subStart = new Date(r[2]);
  const subEnd = new Date(r[3]);
  const checkDate = new Date(date);

  return checkDate >= subStart && checkDate <= subEnd;
});


    for (const sub of seatSubs) {
      const slotJson = sub[6]; // Column G (slot JSON)
      if (!slotJson) continue;

      let subSlots = [];
      try {
        subSlots = JSON.parse(slotJson);
      } catch {
        continue;
      }

      for (const s of subSlots) {
        const subStart = toMinutes(s.start);
        const subEnd = toMinutes(s.end);

        for (const presetKey of Object.keys(slots)) {
          const [pStartStr, pEndStr] = presetKey.split('-');
          const pStart = toMinutes(pStartStr);
          const pEnd = toMinutes(pEndStr);

          // 🔥 Overlap logic
          if (subStart < pEnd && subEnd > pStart) {
            slots[presetKey] = "BOOKED";
          }
        }
      }
    }

    const values = Object.values(slots);
    const bookedCount = values.filter(v => v === "BOOKED").length;

    let seatStatus = "AVAILABLE";
    if (bookedCount === values.length) seatStatus = "FULL";
    else if (bookedCount > 0) seatStatus = "PARTIAL";

    result.push({
      seat,
      isAvailable: seatStatus !== "FULL",
      seatStatus,
      slots,
    });
  }

  return result;
}

function validateSlots(slots) {
  if (!Array.isArray(slots) || slots.length === 0) {
    throw new Error('At least one slot required');
  }

  function toMinutes(t) {
    const [h, m] = t.split(':').map(Number);
    return h * 60 + m;
  }

  for (let i = 0; i < slots.length; i++) {
    const s = slots[i];

    const start = toMinutes(s.start);
    const end = toMinutes(s.end);

    if (Number.isNaN(start) || Number.isNaN(end)) {
      throw new Error('Invalid slot time');
    }

    if (end <= start) {
      throw new Error('Invalid slot range');
    }

    if (end > 1440) {
      throw new Error('Slot cannot exceed 24 hours');
    }

    for (let j = i + 1; j < slots.length; j++) {
      const s2 = slots[j];
      const s2Start = toMinutes(s2.start);
      const s2End = toMinutes(s2.end);

      if (start < s2End && end > s2Start) {
        throw new Error('Overlapping slots not allowed');
      }
    }
  }
}
async function isSeatAvailable(sheetId, seat, startDate, endDate, newSlots = []) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
      range: `${SUBSCRIPTION_SHEET}!A:U`,
  });

  const rows = res.data.values || [];
  if (rows.length <= 1) return true;

  function toMinutes(t) {
    const [h, m] = t.split(':').map(Number);
    return h * 60 + m;
  }

  const reqStart = new Date(startDate);
  const reqEnd = new Date(endDate);

  for (const r of rows.slice(1)) {
    if (r[5] !== 'ACTIVE') continue;
    if (Number(r[1]) !== seat) continue;

    const subStart = new Date(r[2]);
    const subEnd = new Date(r[3]);

    const dateOverlap = reqStart <= subEnd && reqEnd >= subStart;
    if (!dateOverlap) continue;

    const existingSlots = JSON.parse(r[6] || '[]');

    for (const ns of newSlots) {
      const nsStart = toMinutes(ns.start);
      const nsEnd = toMinutes(ns.end);

      for (const es of existingSlots) {
        const esStart = toMinutes(es.start);
        const esEnd = toMinutes(es.end);

        if (nsStart < esEnd && nsEnd > esStart) {
          return false;
        }
      }
    }
  }

  return true;
}

async function getAvailableSeats(sheetId, startDate, endDate) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
    range: `${SUBSCRIPTION_SHEET}!A:U`,

  });

  const rows = res.data.values || [];
  const occupied = new Set();

  const reqStart = new Date(startDate);
  const reqEnd = new Date(endDate);

  for (const r of rows.slice(1)) {
    if (r[5] !== 'ACTIVE') continue;
    const subStart = new Date(r[2]);
    const subEnd = new Date(r[3]);

    if (reqStart <= subEnd && reqEnd >= subStart) {
      occupied.add(Number(r[1]));
    }
  }

  const free = [];
  for (let i = 1; i <= 75; i++) {
    if (!occupied.has(i)) free.push(i);
  }
  return free;
}
const DAY_RATE = 58.33;
const NIGHT_RATE = 66.67;
const DAY_START = 8 * 60;      // 08:00
const DAY_END = 24 * 60;       // 24:00

const PLAN_MULTIPLIER = {
  1: 1,
  3: 3,
  6: 6,
  12: 12,
};

function getDiscount(months) {
  if (months === 3) return 5;
  if (months === 6) return 8;
  if (months === 12) return 15;
  return 0;
}

function calculateSubscriptionPrice({ slots, months }) {
  if (!PLAN_MULTIPLIER[months]) throw new Error('Invalid plan');

  let base = 0;

  for (const s of slots) {
    const [sh, sm] = s.start.split(':').map(Number);
    const [eh, em] = s.end.split(':').map(Number);

    for (let m = sh * 60 + sm; m < eh * 60 + em; m++) {
      base += (m >= DAY_START && m < DAY_END ? DAY_RATE : NIGHT_RATE) / 60;
    }
  }

  base *= PLAN_MULTIPLIER[months];

  const discount = getDiscount(months);
  const discountAmount = (base * discount) / 100;

  return {
    baseAmount: Math.round(base),
    discount,
    discountAmount: Math.round(discountAmount),
    finalAmount: Math.round(base - discountAmount),
  };
}
function generateQuoteId() {
  return `Q-${Date.now()}`;
}

async function createTempQuote(sheetId, { slots, months, discount = 0 }) {
  validateSlots(slots);
  const price = calculateSubscriptionPrice({ slots, months, discount });

  const quoteId = generateQuoteId();
  const now = new Date();
  const expiresAt = new Date(now.getTime() + 10 * 60 * 1000);

  await sheets.spreadsheets.values.append({
    spreadsheetId: sheetId,
    range: `${TEMP_QUOTE_SHEET}!A:I`,
    valueInputOption: 'USER_ENTERED',
    requestBody: {
      values: [[
        quoteId,
        JSON.stringify(slots),
        months,
        price.baseAmount,
        discount,
        price.finalAmount,
        'ACTIVE',
        now.toISOString(),
        expiresAt.toISOString(),
      ]],
    },
  });

  return { quoteId, amount: price.finalAmount, expiresAt };
}

async function getValidQuote(sheetId, quoteId) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
    range: `${TEMP_QUOTE_SHEET}!A:I`,
  });

  const rows = res.data.values || [];
  for (let i = 1; i < rows.length; i++) {
    const r = rows[i];
    if (r[0] === quoteId) {
      if (r[6] !== 'ACTIVE') throw new Error('Quote already used');
      if (new Date() > new Date(r[8])) throw new Error('Quote expired');

      return {
        rowIndex: i + 1,
        slots: JSON.parse(r[1]),
        months: Number(r[2]),
        finalAmount: Number(r[5]),
      };
    }
  }
  throw new Error('Quote not found');
}

async function markQuoteUsed(sheetId, rowIndex) {
  await sheets.spreadsheets.values.update({
    spreadsheetId: sheetId,
    range: `${TEMP_QUOTE_SHEET}!G${rowIndex}`,
    valueInputOption: 'USER_ENTERED',
    requestBody: { values: [['USED']] },
  });
}

/* ------------------------------------------------------------------
   CREATE SUBSCRIPTION (FINAL)
-------------------------------------------------------------------*/

async function createSubscription(sheetId, data) {
  const { email, seat, months, slots, payment, student } = data;

  validateSlots(slots);

  const start = new Date();
  const end = new Date();
  end.setMonth(end.getMonth() + months);

  const startDate = start.toISOString().slice(0, 10);
  const endDate = end.toISOString().slice(0, 10);

  const available = await isSeatAvailable(
    sheetId,
    seat,
    startDate,
    endDate,
    slots
  );

  if (!available) {
    throw new Error('Seat not available');
  }
  let freezeDaysAllowed = 0;
  let seatChangeAllowed = 0;

  if (Number(months) === 1) {
    freezeDaysAllowed = 7;
    seatChangeAllowed = 0;
  }

  if (Number(months) === 3) {
    freezeDaysAllowed = 7;
    seatChangeAllowed = 3;
  }

  if (Number(months) === 6) {
    freezeDaysAllowed = 20;
    seatChangeAllowed = 8;
  }

  if (Number(months) === 12) {
    freezeDaysAllowed = 50;
    seatChangeAllowed = 8;
  }

  await sheets.spreadsheets.values.append({
    spreadsheetId: sheetId,
    range: `${SUBSCRIPTION_SHEET}!A:W`,
    valueInputOption: 'USER_ENTERED',
    requestBody: {
      values: [[
        email,                             // A
        seat,                              // B
        startDate,                         // C
        endDate,                           // D
        months,                            // E
        'ACTIVE',                          // F
        JSON.stringify(slots),             // G
        payment.baseAmount,                // H
        payment.discount,                  // I
        payment.discountAmount,            // J
        payment.finalAmount,               // K
        payment.paidAmount,                // L
        payment.mode,                      // M
        payment.paidAmount >= payment.finalAmount ? 'PAID' : 'PARTIAL', // N
        student?.name || '',               // O
        student?.phone || '',              // P
        student?.idProofType || '',        // Q
        student?.idProofUrl || '',         // R

        freezeDaysAllowed,                 // S → freeze_days_allowed
        0,                                 // T → freeze_days_used
        endDate,                           // U → original_end_date

        seatChangeAllowed,                 // V → seat_change_allowed
        0                                  // W → seat_change_used
      ]],
    },
  });
}
async function addAuditLog(sheetId, log) {
  await sheets.spreadsheets.values.append({
    spreadsheetId: sheetId,
    range: `${AUDIT_SHEET}!A:D`,
    valueInputOption: 'USER_ENTERED',
    requestBody: {
      values: [[new Date().toISOString(), log.admin, log.action, log.details]],
    },
  });
}


async function changeSeat(sheetId, { email, oldSeat, newSeat, admin }) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
    range: `${SUBSCRIPTION_SHEET}!A:W`,
  });

  const rows = res.data.values || [];
  let rowIndex = -1;
  let sub = null;

  // 🔍 Find correct subscription row
  for (let i = 1; i < rows.length; i++) {
    if (rows[i][0] === email && Number(rows[i][1]) === Number(oldSeat)) {
      sub = rows[i];
      rowIndex = i + 1; // because sheet index starts from 1
      break;
    }
  }

  if (!sub) throw new Error("Active subscription not found");

  // ✅ SAFE COLUMN READING
  const status = sub[5] || "";
  const months = Number(sub[4] || 0);

  const seatChangeAllowed =
    sub.length > 21 && sub[21] !== ""
      ? Number(sub[21])
      : 0;

  const seatChangeUsed =
    sub.length > 22 && sub[22] !== ""
      ? Number(sub[22])
      : 0;

  const today = new Date().toISOString().slice(0, 10);
  const startDate = sub[2];
  const endDate = sub[3];

  // 🔒 Only ACTIVE subscription allowed
  if (status !== "ACTIVE") {
    throw new Error("Subscription is not active");
  }

  // 🔒 Block if outside subscription period
  if (today < startDate || today > endDate) {
    throw new Error("Subscription period expired");
  }

  // 🔒 Block 1 month plan
  if (months === 1) {
    throw new Error("Seat change not allowed for 1 month plan");
  }

  // 🔒 Block if limit exceeded
  if (seatChangeUsed >= seatChangeAllowed) {
    throw new Error("Seat change limit exceeded");
  }

  // 🔒 Prevent seat change if currently frozen
  const frozen = await isUserFrozen(sheetId, email);
  if (frozen) {
    throw new Error("Cannot change seat during active freeze");
  }

  // 🔒 Prevent same seat selection
  if (Number(oldSeat) === Number(newSeat)) {
    throw new Error("New seat cannot be same as old seat");
  }

  // 🔒 Check seat availability
  const available = await isSeatAvailable(
    sheetId,
    newSeat,
    startDate,
    endDate
  );

  if (!available) {
    throw new Error("New seat not available");
  }

  // ✅ 1️⃣ Update Seat (Column B)
  await sheets.spreadsheets.values.update({
    spreadsheetId: sheetId,
    range: `${SUBSCRIPTION_SHEET}!B${rowIndex}`,
    valueInputOption: "USER_ENTERED",
    requestBody: {
      values: [[newSeat]],
    },
  });

  // ✅ 2️⃣ Increment seat_change_used (Column W = index 22)
  const updatedUsed = seatChangeUsed + 1;

  await sheets.spreadsheets.values.update({
    spreadsheetId: sheetId,
    range: `${SUBSCRIPTION_SHEET}!W${rowIndex}`,
    valueInputOption: "USER_ENTERED",
    requestBody: {
      values: [[updatedUsed]],
    },
  });

  // 📝 Add audit log
  await addAuditLog(sheetId, {
    admin,
    action: "CHANGE_SEAT",
    details: `${email} changed seat ${oldSeat} → ${newSeat}`,
  });

  return {
    success: true,
    seat_change_used: updatedUsed,
    seat_change_remaining: seatChangeAllowed - updatedUsed,
  };
}

async function getAllSubscriptions() {
  // Read Subscriptions sheet
  const subRes = await sheets.spreadsheets.values.get({
    spreadsheetId: process.env.GOOGLE_SHEET_ID,
    range: `${SUBSCRIPTION_SHEET}!A:W`,


  });

  const subRows = subRes.data.values || [];
  if (subRows.length <= 1) return [];

  // Read TempQuotes sheet (for slots)
  const quoteRes = await sheets.spreadsheets.values.get({
    spreadsheetId: process.env.GOOGLE_SHEET_ID,
    range: `${TEMP_QUOTE_SHEET}!A:I`,
  });

  const quoteRows = quoteRes.data.values || [];

  // Map: quoteId -> slots
  const quoteSlotMap = {};
  for (let i = 1; i < quoteRows.length; i++) {
    const r = quoteRows[i];
    try {
      quoteSlotMap[r[0]] = JSON.parse(r[1]);
    } catch {
      quoteSlotMap[r[0]] = [];
    }
  }

  const subscriptions = [];

  for (let i = 1; i < subRows.length; i++) {
    const r = subRows[i];

    // Only ACTIVE subscriptions
    if (r[5] !== 'ACTIVE') continue;

    subscriptions.push({
  email: r[0],
  seat: Number(r[1]),
  startDate: r[2],
  endDate: r[3],

  months: Number(r[4]),        // Column E
  status: r[5],                // Column F

  freeze_days_allowed: Number(r[18] || 0),   // Column S
  freeze_days_used: Number(r[19] || 0),      // Column T

  seat_change_allowed: Number(r[21] || 0),   // Column V
  seat_change_used: Number(r[22] || 0),      // Column W

  slots: quoteSlotMap[r[0]] || [],
});

  }

  return subscriptions;
}

async function getActiveSubscription(sheetId, email) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
    range: `${SUBSCRIPTION_SHEET}!A:W`,
  });

  const rows = res.data.values || [];
  const today = new Date().toISOString().slice(0, 10);

  for (let i = 1; i < rows.length; i++) {
    const r = rows[i];

    const sheetEmail = (r[0] || "").trim();
    const status = (r[5] || "").trim();
    const start = r[2];
    const end = r[3];

    if (
      sheetEmail === email.trim() &&
      status === "ACTIVE" &&
      today >= start &&
      today <= end
    ) {
      return {
        rowIndex: i + 1,
        email: sheetEmail,
        seat: r[1],
        start_date: start,
        end_date: end,
        freeze_days_allowed: Number(r[18] || 0),
        freeze_days_used: Number(r[19] || 0),
      };
    }
  }

  return null;
}

async function insertFreezeRequest(sheetId, data) {
  await sheets.spreadsheets.values.append({
    spreadsheetId: sheetId,
    range: `${FREEZE_SHEET}!A:J`,
    valueInputOption: 'USER_ENTERED',
    requestBody: {
      values: [[
        data.freeze_id,
        data.email,
        data.start_date,
        data.end_date,
        data.total_days,
        data.status,
        data.requested_at,
        data.approved_at,
        data.approved_by,
        data.rejection_reason
      ]],
    },
  });
}

async function getFreezeById(sheetId, freezeId) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
    range: `${FREEZE_SHEET}!A:J`,
  });

  const rows = res.data.values || [];

  for (const r of rows.slice(1)) {
    if (r[0] === freezeId) {
      return {
        rowIndex: rows.indexOf(r) + 1,
        freeze_id: r[0],
        email: r[1],
        start_date: r[2],
        end_date: r[3],
        total_days: Number(r[4]),
        status: r[5],
      };
    }
  }
  return null;
}

async function updateFreezeStatus(sheetId, rowIndex, updateData) {
  await sheets.spreadsheets.values.update({
    spreadsheetId: sheetId,
    range: `${FREEZE_SHEET}!F${rowIndex}:J${rowIndex}`,
    valueInputOption: 'USER_ENTERED',
    requestBody: {
      values: [[
        updateData.status,
        updateData.approved_at,
        updateData.approved_by,
        updateData.rejection_reason || ''
      ]],
    },
  });
}

async function updateSubscriptionFreeze(sheetId, rowIndex, newEndDate, newUsedDays) {

  // 1️⃣ Update end_date (Column D)
  await sheets.spreadsheets.values.update({
    spreadsheetId: sheetId,
    range: `Subscriptions!D${rowIndex}`,
    valueInputOption: "USER_ENTERED",
    requestBody: {
      values: [[newEndDate]],
    },
  });

  await sheets.spreadsheets.values.update({
    spreadsheetId: sheetId,
    range: `Subscriptions!T${rowIndex}`,
    valueInputOption: "USER_ENTERED",
    requestBody: {
      values: [[newUsedDays]],
    },
  });
}


async function isUserFrozen(sheetId, email) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
    range: `${FREEZE_SHEET}!A:J`,
  });

  const rows = res.data.values || [];
  const today = new Date().toISOString().slice(0, 10);

  for (const r of rows.slice(1)) {
    if (
      r[1] === email &&
      r[5] === "approved" &&
      today >= r[2] &&
      today <= r[3]
    ) {
      return true;
    }
  }

  return false;
}

async function checkOverlappingFreeze(sheetId, email, start, end) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
    range: `${FREEZE_SHEET}!A:J`,
  });

  const rows = res.data.values || [];

  for (const r of rows.slice(1)) {
    if (r[1] !== email) continue;
    if (r[5] === "rejected") continue;

    const existingStart = r[2];
    const existingEnd = r[3];

    if (start <= existingEnd && end >= existingStart) {
      return true;
    }
  }

  return false;
}

async function getAllFreezesByEmail(sheetId, email) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
    range: `${FREEZE_SHEET}!A:J`,
  });

  const rows = res.data.values || [];
  const result = [];

  for (const r of rows.slice(1)) {
    if (r[1] === email) {
      result.push({
        freeze_id: r[0],
        start_date: r[2],
        end_date: r[3],
        total_days: Number(r[4]),
        status: r[5],
      });
    }
  }

  return result;
}

async function getPendingFreezes(sheetId) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
    range: `FreezeRequests!A:J`,
  });

  const rows = res.data.values || [];
  const result = [];

  for (let i = 1; i < rows.length; i++) {
    const r = rows[i];

    if ((r[5] || "").trim() === "pending") {
      result.push({
        freeze_id: r[0],
        email: r[1],
        start_date: r[2],
        end_date: r[3],
        total_days: Number(r[4]),
        requested_at: r[6],
      });
    }
  }

  return result;
}


async function getSubscriptionDetails(sheetId, email) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
    range: `${SUBSCRIPTION_SHEET}!A:W`,

  });

  const rows = res.data.values || [];

  for (let i = 1; i < rows.length; i++) {
    const r = rows[i];

    if ((r[0] || "").trim() === email.trim()) {
      return {
        rowIndex: i + 1,
        email: r[0],
        seat: r[1],
        start_date: r[2],
        end_date: r[3],
        months: r[4],
        status: r[5],
        slot: r[6],
        base_amount: r[7],
        discount_percent: r[8],
        discount_amount: r[9],
        final_amount: r[10],
        paid_amount: r[11],
        payment_mode: r[12],
        payment_status: r[13],
        student_name: r[14],
        student_phone: r[15],
        id_proof_type: r[16],
        id_proof_url: r[17],
        freeze_days_allowed: r[18],
        freeze_days_used: r[19],
        original_end_date: r[20],
        seat_change_allowed: Number(r[21] || 0),
        seat_change_used: Number(r[22] || 0),

      };
    }
  }

  return null;
}

async function updateSubscription(sheetId, identifier, updates) {
  const sub = await getSubscriptionDetails(sheetId, identifier);
  if (!sub) throw new Error("Subscription not found");

  const rowIndex = sub.rowIndex;

  // Prevent seat edit during freeze
  const frozen = await isUserFrozen(sheetId, sub.email);
  if (frozen && updates.seat) {
    throw new Error("Cannot change seat during active freeze");
  }

  const columnMap = {
    email: "A",
    seat: "B",
    start_date: "C",
    end_date: "D",
    months: "E",
    status: "F",
    slot: "G",
    base_amount: "H",
    discount_percent: "I",
    discount_amount: "J",
    final_amount: "K",
    paid_amount: "L",
    payment_mode: "M",
    payment_status: "N",
    student_name: "O",
    student_phone: "P",
    id_proof_type: "Q",
    id_proof_url: "R",
    freeze_days_allowed: "S",
    freeze_days_used: "T",
    original_end_date: "U",
  };

  for (const key of Object.keys(updates)) {
    if (!columnMap[key]) continue;

    await sheets.spreadsheets.values.update({
      spreadsheetId: sheetId,
      range: `${SUBSCRIPTION_SHEET}!${columnMap[key]}${rowIndex}`,
      valueInputOption: "USER_ENTERED",
      requestBody: {
        values: [[updates[key]]],
      },
    });
  }

  return true;
}

async function softDeleteSubscription(sheetId, email) {
  const sub = await getSubscriptionDetails(sheetId, email);
  if (!sub) throw new Error("Subscription not found");

  await sheets.spreadsheets.values.update({
    spreadsheetId: sheetId,
    range: `${SUBSCRIPTION_SHEET}!F${sub.rowIndex}`,
    valueInputOption: "USER_ENTERED",
    requestBody: {
      values: [["DELETED"]],
    },
  });

  return true;
}


async function updateFreeze(sheetId, freezeId, updates) {
  const freeze = await getFreezeById(sheetId, freezeId);
  if (!freeze) throw new Error("Freeze not found");

  const columnMap = {
    start_date: "C",
    end_date: "D",
    status: "F",
  };

  for (const key in updates) {
    if (!columnMap[key]) continue;

    await sheets.spreadsheets.values.update({
      spreadsheetId: sheetId,
      range: `${FREEZE_SHEET}!${columnMap[key]}${freeze.rowIndex}`,
      valueInputOption: "USER_ENTERED",
      requestBody: {
        values: [[updates[key]]],
      },
    });
  }

  return true;
}

async function incrementSeatChangeUsed(sheetId, rowIndex, newValue) {
  await sheets.spreadsheets.values.update({
    spreadsheetId: sheetId,
    range: `Subscriptions!W${rowIndex}`,
    valueInputOption: "USER_ENTERED",
    requestBody: {
      values: [[newValue]],
    },
  });
}

module.exports = {
  findAdminByEmail,
  addAdmin,
  getSeatStatusByDate,
  isSeatAvailable,
  getAvailableSeats,
  calculateSubscriptionPrice,
  createTempQuote,
  getValidQuote,
  markQuoteUsed,
  createSubscription,
  changeSeat,
  getAllSubscriptions,
  addAuditLog,
  getAllStudents,
  getStudent,
  getActiveSubscription,
  insertFreezeRequest,
  getFreezeById,
  updateFreezeStatus,
  updateSubscriptionFreeze,
  isUserFrozen,
 checkOverlappingFreeze,
 getAllFreezesByEmail,
 getPendingFreezes,
 getSubscriptionDetails,
updateSubscription,
softDeleteSubscription,
updateFreeze,
incrementSeatChangeUsed,

};
