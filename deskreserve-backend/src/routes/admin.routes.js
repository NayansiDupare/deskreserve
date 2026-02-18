const express = require('express');
const router = express.Router();
const auth = require('../middlewares/auth.middleware');
const { registerAdmin ,getStudents,
  getStudent,} = require('../controllers/admin.controller');

//  Only logged-in admin can create users
router.post('/register',  registerAdmin);
router.get('/students', auth, getStudents);
router.get('/student', auth, getStudent);

module.exports = router;
