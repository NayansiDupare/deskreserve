const express = require('express');
const router = express.Router();

const auth = require('../middlewares/auth.middleware');

// ✅ Import EVERYTHING from controller
const subscriptionController = require('../controllers/subscription.controller');

/**
 * 💰 Price preview (no lock)
 */
router.post('/quote', auth, subscriptionController.quote);

/**
 * 🔒 Lock quote (TEMP QUOTE)
 */
router.post('/quote/lock', auth, subscriptionController.lockQuote);

/**
 * 🔥 Create subscription (FINAL STEP)
 */
router.post('/create', auth, subscriptionController.create);

/**
 * 🔁 Change seat
 */
router.post('/change-seat',auth, subscriptionController.changeSeat);


/**
 * 📄 Get full subscription details
 */
router.get('/details', auth, subscriptionController.getSubscriptionDetails);

/**
 * ✏ Partial update subscription
 */
router.patch('/update', auth, subscriptionController.updateSubscription);

/**
 *  Delete subscription
 */
router.delete('/delete', auth, subscriptionController.deleteSubscription);

/**
 * ❄ Freeze subscription
 */
router.post('/freeze', auth, subscriptionController.freezeSubscription);


router.get('/all', auth, subscriptionController.getAllSubscriptions);


module.exports = router;
