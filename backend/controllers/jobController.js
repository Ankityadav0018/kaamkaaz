const Job = require('../models/Job');
const User = require('../models/User');
const UserCredits = require('../models/UserCredits'); // UserCredits model
const CreditTransaction = require('../models/CreditTransaction'); // CreditTransaction model
const { createNotification, createUrgentNotification } = require('../utils/notification');
const Razorpay = require('razorpay');
const crypto = require('crypto');

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || 'dummy_key_id',
  key_secret: process.env.RAZORPAY_KEY_SECRET || 'dummy_key_secret',
});

// @desc    Post a new job
// @route   POST /api/jobs
// @access  Recruiter
exports.postJob = async (req, res) => {
  try {
    let { title, description, category, jobType, driverRequirements, requiredSkills, wage, wageType, maxWorkers, location, dateTime, durationValue, durationUnit, isUrgent, paymentMethod } = req.body;

    if (typeof location === 'string') location = JSON.parse(location);
    if (typeof requiredSkills === 'string') requiredSkills = JSON.parse(requiredSkills);
    if (typeof driverRequirements === 'string') driverRequirements = JSON.parse(driverRequirements);
    if (typeof isUrgent === 'string') isUrgent = isUrgent === 'true';

    if (!title || !description || !wage || !location || !dateTime) {
      return res.status(400).json({ success: false, message: req.t('validation.required_field') });
    }

    const images = req.files ? req.files.map(file => file.path) : [];

    const job = await Job.create({
      title, description, category, jobType: jobType || 'general',
      driverRequirements: driverRequirements || {},
      requiredSkills: requiredSkills || [], wage, wageType,
      maxWorkers: maxWorkers || 1, location, dateTime, durationValue,
      durationUnit, isUrgent: isUrgent || false, images,
      recruiterId: req.user.id,
      isPublished: true
    });

    // Handle normal job creation or urgent order creation
    if (isUrgent) {
      const urgentFeeCredits = 1; // 1 credit = 1 urgent job posting

      if (paymentMethod === 'credits' || paymentMethod === 'wallet') {
        const session = await Job.startSession();
        session.startTransaction();
        try {
          // Atomic credit check and deduction using $inc
          const updatedCredits = await UserCredits.findOneAndUpdate(
            { recruiterId: req.user.id, credits: { $gte: urgentFeeCredits } },
            { $inc: { credits: -urgentFeeCredits } },
            { new: true, session }
          );

          if (!updatedCredits) {
            // Insufficient credits or account doesn't exist
            job.urgent_payment_status = 'failed';
            await job.save({ session });
            await session.commitTransaction();
            session.endSession();
            return res.status(400).json({ success: false, message: 'Insufficient job posting credits. Please buy a credit pack.' });
          }

          // Create a credit deduction record
          await CreditTransaction.create([{
            creditsId: updatedCredits._id,
            recruiterId: req.user.id,
            type: 'DEBIT',
            credits: urgentFeeCredits,
            creditsBefore: updatedCredits.credits + urgentFeeCredits,
            creditsAfter: updatedCredits.credits,
            source: 'JOB_POST_DEDUCTION',
            referenceId: job._id.toString(),
            idempotencyKey: req.user.id + '_' + job._id.toString(),
            status: 'SUCCESS',
            description: `Job posting credit used: ${job.title}`
          }], { session });

          // Update Job Payment Status
          job.urgent_payment_id = `credits_${Date.now()}`;
          job.urgent_payment_status = 'success';
          job.urgent_paid_at = new Date();
          job.urgent_fee_amount = urgentFeeCredits;
          await job.save({ session });

          await session.commitTransaction();
          session.endSession();
        } catch (error) {
          await session.abortTransaction();
          session.endSession();
          console.error('Transaction error in credits payment:', error);
          return res.status(500).json({ success: false, message: 'Payment processing failed due to server error' });
        }

        // Trigger notifications immediately
        let busyWorkerIds = [];
        const activeJobs = await Job.find({ status: 'assigned' }).select('assignedWorkerId');
        busyWorkerIds = activeJobs.map(j => j.assignedWorkerId).filter(id => id);

        const workerQuery = {
          role: 'worker',
          kycStatus: 'approved',
          isBlocked: false,
          location: {
            $near: {
              $geometry: { type: 'Point', coordinates: job.location.coordinates },
              $maxDistance: 50000 // 50km radius
            }
          }
        };

        if (busyWorkerIds.length > 0) {
          workerQuery._id = { $nin: busyWorkerIds };
        }

        const nearbyWorkers = await User.find(workerQuery).select('_id name');
        const io = req.app.get('io');
        
        for (const worker of nearbyWorkers) {
          await createUrgentNotification({
            userId: worker._id,
            title: '🚨 URGENT: ' + req.t('notification.job_nearby_title', { title: job.title }),
            message: req.t('notification.job_nearby_message', {
              wage: job.wage,
              wageType: job.wageType === 'daily' ? req.t('general.day') : job.wageType,
              address: job.location.address || req.t('general.nearby')
            }),
            relatedId: job._id,
            io
          });
        }

        return res.status(201).json({
          success: true,
          message: 'Job created and job posting credit used. Notifications sent!',
          isUrgentOrder: false, // Don't trigger razorpay on frontend
          data: job
        });
      }

      // 1. Create a Razorpay Order for ₹9 (paymentMethod === 'razorpay' or default)
      const orderOptions = {
        amount: urgentFeeAmount,
        currency: "INR",
        receipt: `receipt_urgent_${job._id}`
      };

      try {
        const order = await razorpay.orders.create(orderOptions);
        
        job.urgent_order_id = order.id;
        job.urgent_payment_status = 'pending';
        job.urgent_fee_amount = urgentFeeAmount;
        await job.save();

        return res.status(201).json({
          success: true,
          message: 'Job created, please complete urgent payment',
          isUrgentOrder: true,
          data: job,
          order_id: order.id,
          amount: urgentFeeAmount,
          currency: "INR",
          razorpay_key_id: process.env.RAZORPAY_KEY_ID || 'dummy_key_id'
        });
      } catch (err) {
        console.error("Razorpay Order Error:", err);
        return res.status(500).json({ success: false, message: 'Failed to generate urgent payment order', error: err.message });
      }
    } else {
      // Normal Job - send standard notifications
      const workerQuery = {
        role: 'worker',
        kycStatus: 'approved',
        isBlocked: false,
        location: {
          $near: {
            $geometry: { type: 'Point', coordinates: location.coordinates },
            $maxDistance: 25000
          }
        }
      };

      const nearbyWorkers = await User.find(workerQuery).select('_id name');
      const io = req.app.get('io');
      
      for (const worker of nearbyWorkers) {
        await createNotification({
          userId: worker._id,
          title: req.t('notification.job_nearby_title', { title }),
          message: req.t('notification.job_nearby_message', {
            wage,
            wageType: wageType === 'daily' ? req.t('general.day') : wageType,
            address: location.address || req.t('general.nearby')
          }),
          type: 'job_posted',
          relatedId: job._id,
          io
        });
      }
      return res.status(201).json({ success: true, message: req.t('general.success'), data: job });
    }
  } catch (err) {
    res.status(500).json({ success: false, message: req.t('general.server_error'), error: err.message });
  }
};

// @desc    Update a job
// @route   PUT /api/jobs/:id
// @access  Recruiter
exports.updateJob = async (req, res) => {
  try {
    let { title, description, category, jobType, driverRequirements, requiredSkills, wage, wageType, maxWorkers, location, dateTime, durationValue, durationUnit, isUrgent } = req.body;

    const job = await Job.findById(req.params.id);
    if (!job) return res.status(404).json({ success: false, message: req.t('general.not_found') });

    if (job.recruiterId.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: req.t('auth.unauthorized') });
    }

    if (location && typeof location === 'string') location = JSON.parse(location);
    if (requiredSkills && typeof requiredSkills === 'string') requiredSkills = JSON.parse(requiredSkills);
    if (driverRequirements && typeof driverRequirements === 'string') driverRequirements = JSON.parse(driverRequirements);
    if (isUrgent !== undefined && typeof isUrgent === 'string') isUrgent = isUrgent === 'true';

    // Update fields
    if (title) job.title = title;
    if (description) job.description = description;
    if (category) job.category = category;
    if (jobType) job.jobType = jobType;
    if (driverRequirements) job.driverRequirements = driverRequirements;
    if (requiredSkills) job.requiredSkills = requiredSkills;
    if (wage) job.wage = wage;
    if (wageType) job.wageType = wageType;
    if (maxWorkers) job.maxWorkers = maxWorkers;
    if (location) job.location = location;
    if (dateTime) job.dateTime = dateTime;
    if (durationValue) job.durationValue = durationValue;
    if (durationUnit) job.durationUnit = durationUnit;
    
    // Handle urgent status changes and refunds
    if (isUrgent !== undefined) {
      if (job.isUrgent === true && isUrgent === false) {
        // Downgrade to normal - refund fee if paid
        if (job.urgent_payment_status === 'success' && job.urgent_fee_amount > 0) {
          const session = await UserCredits.startSession();
          session.startTransaction();
          try {
            let userCredits = await UserCredits.findOne({ recruiterId: job.recruiterId }).session(session);
            if (!userCredits) {
              userCredits = new UserCredits({ recruiterId: job.recruiterId, credits: 0 });
            }
              const refundCredits = job.urgent_fee_amount; // urgent_fee_amount stores credit count now
              userCredits.credits += refundCredits;
              await userCredits.save({ session });
              
              await CreditTransaction.create([{
                creditsId: userCredits._id,
                recruiterId: job.recruiterId,
                type: 'CREDIT',
                credits: refundCredits,
                creditsBefore: userCredits.credits - refundCredits,
                creditsAfter: userCredits.credits,
                source: 'JOB_POST_REFUND',
                referenceId: job._id.toString(),
                idempotencyKey: `refund_edit_${job._id.toString()}_${Date.now()}`,
                status: 'SUCCESS',
                description: `Credit refund for downgrading urgent job: ${job.title}`
              }], { session });
            
            job.urgent_payment_status = 'none';
            job.urgent_fee_amount = 0;
            job.isUrgent = false;
            
            await job.save({ session });
            await session.commitTransaction();
            session.endSession();
          } catch (err) {
            await session.abortTransaction();
            session.endSession();
            console.error('Credit Refund Error:', err);
            return res.status(500).json({ success: false, message: 'Server error processing credit refund' });
          }
        } else {
          job.isUrgent = false;
        }
      } else if (job.isUrgent === false && isUrgent === true) {
        return res.status(400).json({ success: false, message: 'Upgrading a job to urgent requires payment. Please create a new urgent job.' });
      }
    }

    // Handle new images if provided (in a real app you might want to merge or replace)
    if (req.files && req.files.length > 0) {
      job.images = req.files.map(file => file.path);
    }

    await job.save();

    res.status(200).json({ success: true, message: req.t('general.success'), data: job });
  } catch (err) {
    res.status(500).json({ success: false, message: req.t('general.server_error'), error: err.message });
  }
};

// @desc    Get nearby jobs (Worker view)
// @route   GET /api/jobs/nearby
exports.getNearbyJobs = async (req, res) => {
  try {
    const {
      lat, lng,
      radius = 50,
      category,
      jobType,
      minWage = 0,
      maxWage = 99999,
      urgentOnly = 'false',
      keyword,
      page = 1,
      limit = 30
    } = req.query;

    const pipeline = [];

    // 1. Geo-spatial filtering (Must be first if using $geoNear)
    // IMPORTANT: If lat/lng are missing we do NOT fall back to returning all jobs —
    // that would ignore the user's distance filter entirely and show jobs 100s of km away.
    // Instead, we return an empty result set so the UI can prompt the user to enable location.
    const parsedLat = lat ? parseFloat(lat) : null;
    const parsedLng = lng ? parseFloat(lng) : null;
    const hasLocation = parsedLat !== null && parsedLng !== null &&
      !isNaN(parsedLat) && !isNaN(parsedLng);

    // If no radius is explicitly selected by the client, default to a strict 50km radius.
    // If a radius IS provided (e.g. explore mode = 99999), respect it without a hard cap.
    const radiusKm = Math.max(parseFloat(radius) || 50, 1);
    const radiusMeters = radiusKm * 1000;

    if (hasLocation) {
      pipeline.push({
        $geoNear: {
          near: { type: 'Point', coordinates: [parsedLng, parsedLat] },
          distanceField: 'distance',
          maxDistance: radiusMeters,
          query: { status: 'open', isPublished: true },
          spherical: true
        }
      });
    } else {
      // No location provided — return empty to avoid showing geographically irrelevant jobs
      return res.status(200).json({ success: true, count: 0, total: 0, data: [] });
    }

    // 2. Additional Filters
    const matchStage = {};
    if (category) matchStage.category = category;
    if (urgentOnly === 'true') matchStage.isUrgent = true;

    // Wage Range
    matchStage.wage = { $gte: parseFloat(minWage), $lte: parseFloat(maxWage) };

    // Keyword Search
    if (keyword) {
      matchStage.$or = [
        { title: { $regex: keyword, $options: 'i' } },
        { description: { $regex: keyword, $options: 'i' } }
      ];
    }

    // --- Worker type filtering ---
    // General workers only see general jobs.
    // Driver workers see both general AND driver jobs.
    // If the caller explicitly filters by jobType, honour that but still enforce visibility.
    if (req.user && req.user.role === 'worker') {
      const User = require('../models/User');
      const requestingUser = await User.findById(req.user.id).select('workerType');
      const workerType = requestingUser?.workerType || 'general';

      if (jobType) {
        // Explicit filter: only allow driver filter for actual drivers
        if (jobType === 'driver' && workerType !== 'driver') {
          // Non-driver asked for driver jobs → return empty
          return res.status(200).json({ success: true, data: [], total: 0 });
        }
        matchStage.jobType = jobType;
      } else {
        if (workerType === 'general') {
          // General workers: exclude driver-type jobs entirely
          matchStage.jobType = { $ne: 'driver' };
        }
        // Driver workers: no restriction (they see both general + driver jobs)
      }
    } else {
      // Recruiter / admin or unauthenticated: apply explicit filter if given
      if (jobType) matchStage.jobType = jobType;
    }
    // ----------------------------

    pipeline.push({ $match: matchStage });

    // 3. Populate Recruiter Data
    pipeline.push({
      $lookup: {
        from: 'users',
        localField: 'recruiterId',
        foreignField: '_id',
        as: 'recruiter'
      }
    });
    pipeline.push({ $unwind: '$recruiter' });

    // 4. Pagination
    pipeline.push({ $skip: (parseInt(page) - 1) * parseInt(limit) });
    pipeline.push({ $limit: parseInt(limit) });

    // 5. Final Projection
    pipeline.push({
      $project: {
        'recruiter.password': 0,
        'recruiter.otp': 0,
        'recruiter.fcmToken': 0,
        'recruiter.documentImage': 0
      }
    });

    let jobs = await Job.aggregate(pipeline);

    // Flatten recruiter data to match previous structure
    jobs = jobs.map(j => ({
      ...j,
      recruiterId: {
        _id: j.recruiter._id,
        name: j.recruiter.name,
        companyName: j.recruiter.companyName,
        rating: j.recruiter.rating
      },
      distance: j.distance ? j.distance / 1000 : null // Convert to KM
    }));

    // Mark which jobs the worker has applied for
    if (req.user && req.user.role === 'worker') {
      const Application = require('../models/Application');
      const applied = await Application.find({ workerId: req.user.id }).select('jobId');
      const appliedIds = new Set(applied.map(a => a.jobId.toString()));
      jobs = jobs.map(j => ({ ...j, isApplied: appliedIds.has((j._id || j.id).toString()) }));
    }


    res.status(200).json({ success: true, count: jobs.length, data: jobs });
  } catch (err) {
    res.status(500).json({ success: false, message: req.t('general.server_error'), error: err.message });
  }
};

// @desc    Get single job detail
// @route   GET /api/jobs/:id
exports.getJobById = async (req, res) => {
  try {
    const job = await Job.findById(req.params.id)
      .populate('recruiterId', 'name companyName rating phone businessArea')
      .populate('assignedWorkerId', 'name skills rating');

    if (!job) return res.status(404).json({ success: false, message: req.t('general.not_found') });

    let jobData = job.toObject();

    // Only reveal recruiter phone if worker is assigned to job
    if (req.user?.role === 'worker' && job.assignedWorkerId?.toString() !== req.user.id) {
      if (jobData.recruiterId) delete jobData.recruiterId.phone;
    }

    res.status(200).json({ success: true, data: jobData });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get recruiter's own jobs
// @route   GET /api/jobs/my-jobs
exports.getMyJobs = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const query = { recruiterId: req.user.id };
    if (status) query.status = status;

    const total = await Job.countDocuments(query);
    const jobs = await Job.find(query)
      .populate('assignedWorkerId', 'name phone skills rating profileImage')
      .sort({ createdAt: -1 })
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(parseInt(limit));

    res.status(200).json({ success: true, count: jobs.length, total, data: jobs });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Update job status (complete/cancel)
// @route   PUT /api/jobs/:id/status
exports.updateJobStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const job = await Job.findById(req.params.id);
    if (!job) return res.status(404).json({ success: false, message: req.t('general.not_found') });
    if (job.recruiterId.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: req.t('auth.unauthorized') });
    }

    job.status = status;
    await job.save();

    // If completed and worker assigned, increment their count and update application status
    if (status === 'completed' && job.assignedWorkerId) {
      await User.findByIdAndUpdate(job.assignedWorkerId, {
        $inc: { completedJobsCount: 1, experienceDays: job.durationValue || 1 }
      });
      const Application = require('../models/Application');
      await Application.findOneAndUpdate(
        { jobId: job._id, workerId: job.assignedWorkerId, status: 'accepted' },
        { status: 'completed' }
      );
    }

    res.status(200).json({ success: true, message: req.t('general.success'), data: job });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Delete job (recruiter/admin)
// @route   DELETE /api/jobs/:id
exports.deleteJob = async (req, res) => {
  try {
    const job = await Job.findById(req.params.id);
    if (!job) return res.status(404).json({ success: false, message: req.t('general.not_found') });
    if (job.recruiterId.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: req.t('auth.unauthorized') });
    }

    if (job.isUrgent && job.urgent_payment_status === 'success' && job.urgent_fee_amount > 0) {
      const session = await UserCredits.startSession();
      session.startTransaction();
      try {
        let userCredits = await UserCredits.findOne({ recruiterId: job.recruiterId }).session(session);
        if (!userCredits) {
          userCredits = new UserCredits({ recruiterId: job.recruiterId, credits: 0 });
        }
          const refundCredits = job.urgent_fee_amount; // urgent_fee_amount stores credit count
          userCredits.credits += refundCredits;
          await userCredits.save({ session });
          
          await CreditTransaction.create([{
            creditsId: userCredits._id,
            recruiterId: job.recruiterId,
            type: 'CREDIT',
            credits: refundCredits,
            creditsBefore: userCredits.credits - refundCredits,
            creditsAfter: userCredits.credits,
            source: 'JOB_POST_REFUND',
            referenceId: job._id.toString(),
            idempotencyKey: `refund_del_${job._id.toString()}_${Date.now()}`,
            status: 'SUCCESS',
            description: `Credit refund for deleted urgent job: ${job.title}`
          }], { session });
        await job.deleteOne({ session });
        await session.commitTransaction();
        session.endSession();
        return res.status(200).json({ success: true, message: req.t('general.deleted') });
      } catch (err) {
        await session.abortTransaction();
        session.endSession();
        console.error('Credit Refund Error:', err);
        return res.status(500).json({ success: false, message: 'Server error processing credit refund during deletion' });
      }
    }

    await job.deleteOne();
    res.status(200).json({ success: true, message: req.t('general.deleted') });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get localized share text for a job
// @route   GET /api/jobs/:id/share-text
// @access  Private
exports.getJobShareText = async (req, res) => {
  try {
    const job = await Job.findById(req.params.id);
    if (!job) return res.status(404).json({ success: false, message: req.t('general.not_found') });

    const jobCode = job._id.toString().slice(-6).toUpperCase();
    const area = job.location.address.split(',')[0] || 'पास ही में';
    const duration = `${job.durationValue} ${job.durationUnit}`;
    const emoji = job.category === 'Driver' ? '🚗' : '🔨';

    const text = `${emoji} *${job.category}* की ज़रूरत है!\n📍 *जगह:* ${area}\n💰 *मजदूरी:* ₹${job.wage}/${job.wageType === 'daily' ? 'दिन' : 'महीना'}\n📅 *समय:* ${duration}\n\nआज ही *Kaamkaaz App* पर अप्लाई करें।\nकोड: *${jobCode}*\n\nऐप डाउनलोड करें: https://kaamkaaz.app/download`;

    const whatsappUrl = `https://wa.me/?text=${encodeURIComponent(text)}`;

    res.status(200).json({ success: true, text, whatsappUrl });
  } catch (err) {
    res.status(500).json({ success: false, message: req.t('general.server_error') });
  }
};

// @desc    Verify Razorpay Urgent Payment
// @route   POST /api/jobs/:id/verify-urgent-payment
// @access  Recruiter
exports.verifyUrgentPayment = async (req, res) => {
  try {
    const { razorpay_payment_id, razorpay_order_id, razorpay_signature } = req.body;
    const jobId = req.params.id;

    const job = await Job.findById(jobId);
    if (!job) return res.status(404).json({ success: false, message: req.t('general.not_found') });

    if (job.urgent_payment_status === 'success') {
      return res.status(400).json({ success: false, message: 'Payment already verified' });
    }

    const secret = process.env.RAZORPAY_KEY_SECRET || 'dummy_key_secret';
    const generated_signature = crypto.createHmac('sha256', secret)
      .update(razorpay_order_id + "|" + razorpay_payment_id)
      .digest('hex');

    if (generated_signature !== razorpay_signature) {
      job.urgent_payment_status = 'failed';
      await job.save();
      return res.status(400).json({ success: false, message: 'Payment verification failed. Invalid signature.' });
    }

    // Payment Successful
    job.urgent_payment_id = razorpay_payment_id;
    job.urgent_payment_status = 'success';
    job.urgent_paid_at = new Date();
    job.urgent_fee_amount = 900; // 900 paise = ₹9
    await job.save();

    // Now trigger the 50km radius broadcast
    let busyWorkerIds = [];
    const activeJobs = await Job.find({ status: 'assigned' }).select('assignedWorkerId');
    busyWorkerIds = activeJobs.map(j => j.assignedWorkerId).filter(id => id);

    const workerQuery = {
      role: 'worker',
      kycStatus: 'approved',
      isBlocked: false,
      location: {
        $near: {
          $geometry: { type: 'Point', coordinates: job.location.coordinates },
          $maxDistance: 50000 // 50km radius
        }
      }
    };

    if (busyWorkerIds.length > 0) {
      workerQuery._id = { $nin: busyWorkerIds };
    }

    const nearbyWorkers = await User.find(workerQuery).select('_id name');
    const io = req.app.get('io');
    
    for (const worker of nearbyWorkers) {
      await createUrgentNotification({
        userId: worker._id,
        title: '🚨 URGENT: ' + req.t('notification.job_nearby_title', { title: job.title }),
        message: req.t('notification.job_nearby_message', {
          wage: job.wage,
          wageType: job.wageType === 'daily' ? req.t('general.day') : job.wageType,
          address: job.location.address || req.t('general.nearby')
        }),
        relatedId: job._id,
        io
      });
    }

    res.status(200).json({ success: true, message: 'Payment verified and urgent notifications sent!', data: job });
  } catch (err) {
    console.error("verifyUrgentPayment error:", err);
    res.status(500).json({ success: false, message: req.t('general.server_error'), error: err.message });
  }
};
