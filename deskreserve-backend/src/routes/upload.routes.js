const express = require('express');
const multer = require('multer');
const path = require('path');
const auth = require('../middlewares/auth.middleware');

const router = express.Router();

const storage = multer.diskStorage({
  destination: 'uploads/idproofs',
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  },
});

const upload = multer({ storage });

router.post(
  '/id-proof',
  auth,
  upload.single('file'),
  (req, res) => {
    const url = `${req.protocol}://${req.get('host')}/uploads/idproofs/${req.file.filename}`;
    res.json({ url });
  }
);

module.exports = router;
