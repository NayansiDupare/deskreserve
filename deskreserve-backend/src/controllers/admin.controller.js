const { addAdmin, addAuditLog, findAdminByEmail,getAllStudents,
  getStudent, } = require('../services/sheets.service');

exports.registerAdmin = async (req, res) => {
  try {
    const { email, password, role } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'email and password required' });
    }

    // Check if already exists
    const existing = await findAdminByEmail(process.env.GOOGLE_SHEET_ID, email);
    if (existing) {
      return res.status(400).json({ error: 'User already exists' });
    }

    await addAdmin(process.env.GOOGLE_SHEET_ID, {
      email,
      password,
      role,
    });

    await addAuditLog(process.env.GOOGLE_SHEET_ID, {
      admin: req.admin?.email || 'SYSTEM',
      action: 'REGISTER_ADMIN',
      details: `Created user ${email} with role ${role || 'ADMIN'}`,
    });

    res.json({
      success: true,
      message: 'User registered successfully',
    });
  } catch (err) {
    console.error('REGISTER ADMIN ERROR:', err);
    res.status(500).json({ error: err.message });
  }
};

exports.getStudents = async (req, res) => {
  try {
    const students = await getAllStudents(
      process.env.GOOGLE_SHEET_ID
    );
    res.json(students);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getStudent = async (req, res) => {
  try {
    const { email, seat } = req.query;

    const student = await getStudent(
      process.env.GOOGLE_SHEET_ID,
      { email, seat }
    );

    if (!student) {
      return res.status(404).json({ error: 'Student not found' });
    }

    res.json(student);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
