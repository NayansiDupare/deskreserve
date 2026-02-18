const express = require("express");
const router = express.Router();
const freezeController = require("../controllers/freeze.controller");
const verifyToken = require("../middlewares/auth.middleware");
const verifyAdmin = require("../middlewares/admin.middleware");

router.post("/request", verifyToken, freezeController.requestFreeze);
router.post("/action", verifyToken, verifyAdmin, freezeController.approveFreeze);
router.get("/me", verifyToken, freezeController.getMyFreezeStatus);
router.get("/pending", verifyToken, verifyAdmin, freezeController.getPendingFreezes);

module.exports = router;
