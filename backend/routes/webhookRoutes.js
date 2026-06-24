const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const Job = require('../models/Job');
const User = require('../models/User');
const Wallet = require('../models/Wallet');
const WalletTransaction = require('../models/WalletTransaction');
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
        // 1. Check if it's a Wallet Top-up
        const topupOrder = await RazorpayTopupOrder.findOne({ razorpayOrderId: razorpay_order_id });
        
        if (topupOrder) {
          // Idempotency check: if a transaction with this payment ID exists, we already processed it
          const existingTx = await WalletTransaction.findOne({ idempotencyKey: razorpay_payment_id });
          if (existingTx) {
            console.log('Webhook already processed for payment:', razorpay_payment_id);
            return res.status(200).json({ status: 'ok', message: 'Already processed' });
          }

          // Atomic processing
          const session = await Wallet.startSession();
          session.startTransaction();
          try {
            // Re-fetch wallet with lock
            const wallet = await Wallet.findOne({ recruiterId: topupOrder.recruiterId }).session(session);
            if (!wallet) throw new Error('Wallet not found');

            const currentBalance = wallet.balance;
            const amountPaise = topupOrder.amount;
            const newBalance = currentBalance + amountPaise;

            // Update Wallet
            wallet.balance = newBalance;
            await wallet.save({ session });

            // Create Wallet Transaction
            await WalletTransaction.create([{
              walletId: wallet._id,
              recruiterId: wallet.recruiterId,
              type: 'CREDIT',
              amount: amountPaise,
              balanceBefore: currentBalance,
              balanceAfter: newBalance,
              source: 'RAZORPAY_TOPUP',
              referenceId: razorpay_payment_id,
              idempotencyKey: razorpay_payment_id,
              status: 'SUCCESS',
              description: 'Wallet Top-up'
            }], { session });

            // Update Order Status
            topupOrder.status = 'PAID';
            topupOrder.razorpayPaymentId = razorpay_payment_id;
            topupOrder.webhookReceivedAt = new Date();
            await topupOrder.save({ session });

            await session.commitTransaction();
            session.endSession();

            // Notifications
            const io = req.app.get('io');
            await createNotification({
              userId: wallet.recruiterId,
              title: 'Wallet Top-up Successful',
              message: `₹${(amountPaise / 100).toFixed(2)} has been added to your wallet.`,
              type: 'wallet_topup',
              io
            });
            console.log(`Wallet top-up successful for recruiter ${wallet.recruiterId}`);
            return res.status(200).json({ status: 'ok' });
          } catch (txError) {
            await session.abortTransaction();
            session.endSession();
            console.error('Wallet Top-up Transaction Error:', txError);
            return res.status(500).send('Internal Server Error');
          }
        }

        // 2. Otherwise check if it's an Urgent Job payment (Direct Razorpay payment)
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
