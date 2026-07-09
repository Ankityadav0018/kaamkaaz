const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const Job = require('../models/Job');
const User = require('../models/User');
const UserCredits = require('../models/UserCredits'); // UserCredits model (stored in 'wallets' collection)
const CreditTransaction = require('../models/CreditTransaction'); // CreditTransaction model
const RazorpayTopupOrder = require('../models/RazorpayTopupOrder');
const { createNotification, createUrgentNotification } = require('../utils/notification');

router.post('/razorpay', express.raw({ type: 'application/json' }), async (req, res) => {
  const secret = process.env.RAZORPAY_WEBHOOK_SECRET || process.env.RAZORPAY_KEY_SECRET || 'dummy_key_secret';
  const signature = req.headers['x-razorpay-signature'];

  if (!signature) {
    return res.status(400).send('Signature missing');
  }

  const expectedSignature = crypto.createHmac('sha256', secret)
    .update(req.body)
    .digest('hex');

  if (signature === expectedSignature) {
    console.log('Razorpay request is legit');

    let event;
    try {
      event = JSON.parse(req.body.toString());
    } catch (e) {
      return res.status(400).send('Invalid JSON payload');
    }

    if (event.event === 'payment.captured') {
      const payment = event.payload.payment.entity;
      const razorpay_order_id = payment.order_id;
      const razorpay_payment_id = payment.id;

      try {
        // 1. Check if it's a Credit Pack Purchase
        const packOrder = await RazorpayTopupOrder.findOne({ razorpayOrderId: razorpay_order_id });

        if (packOrder) {
          // Idempotency check: if a transaction with this payment ID exists, already processed
          const existingTx = await CreditTransaction.findOne({ idempotencyKey: razorpay_payment_id });
          if (existingTx) {
            console.log('Webhook already processed for payment:', razorpay_payment_id);
            return res.status(200).json({ status: 'ok', message: 'Already processed' });
          }

          // Atomic credit granting
          const session = await UserCredits.startSession();
          session.startTransaction();
          try {
            const userCredits = await UserCredits.findOne({ recruiterId: packOrder.recruiterId }).session(session);
            if (!userCredits) throw new Error('Credit account not found');

            const currentCredits = userCredits.credits;
            const creditsToAdd = packOrder.creditsToGrant;
            const newCredits = currentCredits + creditsToAdd;

            // Update credit balance
            userCredits.credits = newCredits;
            await userCredits.save({ session });

            // Create credit transaction record
            await CreditTransaction.create([{
              creditsId: userCredits._id,
              recruiterId: userCredits.recruiterId,
              type: 'CREDIT',
              credits: creditsToAdd,
              creditsBefore: currentCredits,
              creditsAfter: newCredits,
              source: 'CREDIT_PACK_PURCHASE',
              packId: packOrder.packId,
              referenceId: razorpay_payment_id,
              idempotencyKey: razorpay_payment_id,
              status: 'SUCCESS',
              description: `Credit Pack Purchase: ${packOrder.packId} (+${creditsToAdd} credits)`
            }], { session });

            // Update Order Status
            packOrder.status = 'PAID';
            packOrder.razorpayPaymentId = razorpay_payment_id;
            packOrder.webhookReceivedAt = new Date();
            await packOrder.save({ session });

            await session.commitTransaction();
            session.endSession();

            // Send notification
            const io = req.app.get('io');
            await createNotification({
              userId: userCredits.recruiterId,
              title: 'Job Credits Added!',
              message: `${creditsToAdd} job posting credits have been added to your account.`,
              type: 'credit_pack_purchase',
              io
            });
            console.log(`Credit pack purchase successful for recruiter ${userCredits.recruiterId}: +${creditsToAdd} credits`);
            return res.status(200).json({ status: 'ok' });
          } catch (txError) {
            await session.abortTransaction();
            session.endSession();
            console.error('Credit Pack Purchase Transaction Error:', txError);
            return res.status(500).send('Internal Server Error');
          }
        }

        // 2. Check if it's an Urgent Job payment (Direct Razorpay payment)
        const job = await Job.findOne({ urgent_order_id: razorpay_order_id });
        if (job) {
          if (job.urgent_payment_status === 'success') {
            return res.status(200).json({ status: 'ok', message: 'Already processed' });
          }

          job.urgent_payment_id = razorpay_payment_id;
          job.urgent_payment_status = 'success';
          job.urgent_paid_at = new Date();
          job.urgent_fee_amount = 900; // 900 paise = ₹9
          await job.save();

          // Trigger notifications
          const activeJobs = await Job.find({ status: 'assigned' }).select('assignedWorkerId');
          const busyWorkerIds = activeJobs.map(j => j.assignedWorkerId).filter(id => id);

          const workerQuery = {
            role: 'worker',
            kycStatus: 'approved',
            isBlocked: false,
            location: {
              $near: {
                $geometry: { type: 'Point', coordinates: job.location.coordinates },
                $maxDistance: 50000
              }
            }
          };

          if (busyWorkerIds.length > 0) {
            workerQuery._id = { $nin: busyWorkerIds };
          }

          const nearbyWorkers = await User.find(workerQuery).select('_id name');
          const io = req.app.get('io');

          for (const worker of nearbyWorkers) {
            const titleMsg = job.title;
            const wageMsg = `Wage: ${job.wage}`;
            await createUrgentNotification({
              userId: worker._id,
              title: '🚨 URGENT: Job Nearby: ' + titleMsg,
              message: `${wageMsg} - Within 50km`,
              relatedId: job._id,
              io
            });
          }

          return res.status(200).json({ status: 'ok' });
        }

        // Order not found in either system
        console.error(`Order ${razorpay_order_id} not found in DB`);
        return res.status(200).json({ status: 'ok', message: 'Order not found' });
      } catch (err) {
        console.error('Webhook processing error:', err);
        return res.status(500).send('Internal Server Error');
      }
    } else {
      // Other events like payment.failed
      return res.status(200).json({ status: 'ok' });
    }
  } else {
    return res.status(400).send('Invalid signature');
  }
});

module.exports = router;
