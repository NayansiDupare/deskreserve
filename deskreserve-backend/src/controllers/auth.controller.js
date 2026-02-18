const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const {
  findAdminByEmail,
  addAdmin,
  addAuditLog,
} = require('../services/sheets.service');

/**
 * 🔐 REGISTER (Admin / Staff)
 */
exports.register = async (req, res) => {
  try {
    const { email, password, role } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        error: 'email and password are required',
      });
    }

    const existing = await findAdminByEmail(
      process.env.GOOGLE_SHEET_ID,
      email
    );

    if (existing) {
      return res.status(400).json({
        error: 'User already exists',
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await addAdmin(process.env.GOOGLE_SHEET_ID, {
      email,
      password: hashedPassword,
      role: role || 'STAFF',
    });

    await addAuditLog(process.env.GOOGLE_SHEET_ID, {
      admin: email,
      action: 'REGISTER',
      details: `User registered with role ${role || 'STAFF'}`,
    });

    res.json({ success: true });
  } catch (err) {
    console.error('REGISTER ERROR:', err);
    res.status(500).json({ error: err.message });
  }
};

/**
 * 🔐 LOGIN
 */
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const admin = await findAdminByEmail(
      process.env.GOOGLE_SHEET_ID,
      email
    );

    if (!admin) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const match = await bcrypt.compare(password, admin.password_hash);
    if (!match) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { email: admin.email, role: admin.role },
      process.env.JWT_SECRET,
      { expiresIn: '1d' }
    );

    await addAuditLog(process.env.GOOGLE_SHEET_ID, {
      admin: email,
      action: 'LOGIN',
      details: 'User logged in',
    });

    res.json({ token });
  } catch (err) {
    console.error('LOGIN ERROR:', err);
    res.status(500).json({ error: err.message });
  }
};
