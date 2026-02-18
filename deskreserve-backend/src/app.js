const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth.routes');
const adminRoutes = require('./routes/admin.routes');
const subscriptionRoutes = require('./routes/subscription.routes');
const seatsRoutes = require('./routes/seats.routes');
const analyticsRoutes = require('./routes/analytics.routes');
const uploadRoutes = require('./routes/upload.routes');
const freezeRoutes = require('./routes/freeze.routes');



const app = express();

app.use(cors());
app.use(express.json());

/**
 * 🔐 Core APIs
 */


app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);

/**
 * 🔥 Subscription-first system
 */
app.use('/api/subscription', subscriptionRoutes);
app.use('/api/seats', seatsRoutes);


app.use('/api/analytics', analyticsRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/freeze', freezeRoutes);





/**
 * ❌ Booking APIs intentionally NOT mounted
 * (Deprecated – subscription owns everything)
 */

module.exports = app;
