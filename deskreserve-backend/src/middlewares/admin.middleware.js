module.exports = function verifyAdmin(req, res, next) {
  try {
    // req.user is set by auth middleware
    if (!req.user || !req.user.role) {
      return res.status(403).json({
        message: "Access denied"
      });
    }

    if (req.user.role !== "ADMIN") {
      return res.status(403).json({
        message: "Admin access required"
      });
    }

    next();
  } catch (error) {
    return res.status(500).json({
      message: "Server error"
    });
  }
};
