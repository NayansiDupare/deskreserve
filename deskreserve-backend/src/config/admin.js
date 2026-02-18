const bcrypt = require('bcrypt');

const ADMIN_EMAIL = 'admin@deskreserve.com';
const ADMIN_PASSWORD_HASH = bcrypt.hashSync('admin123', 10);

module.exports = {
  ADMIN_EMAIL,
  ADMIN_PASSWORD_HASH,
};
