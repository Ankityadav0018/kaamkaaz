import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/job_provider.dart';
import '../../services/location_service.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../shared/map_picker_screen.dart';
import '../../utils/app_colors.dart';
import '../../l10n/locale_keys.g.dart';
import '../../services/secure_upload_service.dart';
import '../../models/job_model.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:kaamkaaz/services/credits_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/api_config.dart';

import '../../widgets/brand_logo.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class PostJobScreen extends ConsumerStatefulWidget {
  final JobModel? existingJob;
  const PostJobScreen({super.key, this.existingJob});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _wageCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '1');

  String _category = 'construction';
  String _wageType = 'daily';
  String _durationUnit = 'days';
  bool _isUrgent = false;
  String _jobType = 'general';
  String? _driverVehicleType;
  bool _driverMustOwnVehicle = false;
  bool _driverOutstation = false;
  // --- Enhanced driver fields ---
  String? _driverLicenseType; // LMV, HMV, MCWG, etc.
  int _driverMinExperienceYears = 0;
  final bool _driverNightShift = false;
  bool _driverFuelAllowance = false;
  bool _driverTollAllowance = false;
  bool _driverAccommodation = false;
  bool _driverUniformProvided = false;
  String? _driverShiftTiming; // day, night, flexible
  String? _driverTripType; // local, intercity, outstation
  // --------------------------------
  DateTime _dateTime = DateTime.now().add(const Duration(days: 1));
  double? _lat, _lng;
  bool _fetchingLocation = false;
  bool _isPublishing = false;
  int _maxWorkers = 1;

  final List<String> _imagePaths = [];
  final ImagePicker _picker = ImagePicker();
  
  late Razorpay _razorpay;
  String? _currentRazorpayOrderId;
  String? _currentJobId;
  int _creditsBalance = 0;

  final List<String> _selectedSkills = [];
  final List<String> _allSkills = [
    LocaleKeys.skillConstruction.tr(),
    LocaleKeys.skillPlumbing.tr(),
    LocaleKeys.skillElectrical.tr(),
    LocaleKeys.skillCarpentry.tr(),
    LocaleKeys.skillPainting.tr(),
    LocaleKeys.skillFarming.tr(),
    LocaleKeys.skillCleaning.tr(),
    LocaleKeys.skillCooking.tr(),
    LocaleKeys.skillDriving.tr(),
    LocaleKeys.skillSecurity.tr(),
    LocaleKeys.skillMasonry.tr(),
    LocaleKeys.skillWelding.tr(),
    LocaleKeys.skillLoading.tr(),
    LocaleKeys.skillACRepair.tr(),
    LocaleKeys.skillTailoring.tr(),
  ];

  final List<String> _driverSkills = [
    LocaleKeys.skillCommercialDriving.tr(),
    LocaleKeys.skillChauffeur.tr(),
    LocaleKeys.skillTruckDriving.tr(),
    LocaleKeys.skillDelivery.tr(),
    LocaleKeys.skillVehicleMaintenance.tr(),
    LocaleKeys.skillNavigation.tr(),
    LocaleKeys.skillOutstationDriving.tr(),
    LocaleKeys.skillLongRoute.tr(),
  ];

  List<String> get _currentSkillsList =>
      _jobType == 'driver' ? _driverSkills : _allSkills;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    if (widget.existingJob != null) {
      final job = widget.existingJob!;
      _titleCtrl.text = job.title;
      _descCtrl.text = job.description;
      _wageCtrl.text = job.wage.toString();
      _addressCtrl.text = job.location.address;
      _durationCtrl.text = job.durationValue.toString();
      _category = job.category;
      _wageType = job.wageType;
      _durationUnit = job.durationUnit;
      _isUrgent = job.isUrgent;
      _jobType = job.jobType;
      _selectedSkills.addAll(job.requiredSkills);
      if (job.driverRequirements != null) {
        final dr = job.driverRequirements!;
        _driverVehicleType = dr['vehicleType'];
        _driverMustOwnVehicle = dr['mustHaveOwnVehicle'] ?? false;
        _driverOutstation = dr['outstationRequired'] ?? false;
        _driverLicenseType = dr['licenseType'];
        _driverMinExperienceYears = dr['minExperienceYears'] ?? 0;
        _driverFuelAllowance = dr['fuelAllowance'] ?? false;
        _driverTollAllowance = dr['tollAllowance'] ?? false;
        _driverAccommodation = dr['accommodation'] ?? false;
        _driverUniformProvided = dr['uniformProvided'] ?? false;
        _driverShiftTiming = dr['shiftTiming'];
        _driverTripType = dr['tripType'];
      }
      _dateTime = job.dateTime;
      if (job.location.coordinates.isNotEmpty) {
        _lng = job.location.coordinates[0];
        _lat = job.location.coordinates[1];
      }
      _maxWorkers = job.maxWorkers;
      // Note: existing images are not pre-filled in UI currently to avoid complexity,
      // but you might want to show them in a real app.
    }
  }

  Future<void> _fetchWallet() async {
    try {
      final res = await CreditsService.getCredits();
      if (mounted) {
        setState(() => _creditsBalance = (res['data']?['credits_balance'] as num?)?.toInt() ?? 0);
      }
    } catch (e) {
      // Silently ignore
    }
  }


  final List<Map<String, dynamic>> _categories = [
    {
      'key': 'construction',
      'emoji': '🏗️',
      'label': LocaleKeys.construction.tr()
    },
    {'key': 'farming', 'emoji': '🌾', 'label': LocaleKeys.farming.tr()},
    {'key': 'cleaning', 'emoji': '🧹', 'label': LocaleKeys.cleaning.tr()},
    {'key': 'painting', 'emoji': '🎨', 'label': LocaleKeys.painting.tr()},
    {'key': 'plumbing', 'emoji': '🔧', 'label': LocaleKeys.plumbing.tr()},
    {'key': 'electrical', 'emoji': '⚡', 'label': LocaleKeys.electrical.tr()},
    {'key': 'carpentry', 'emoji': '🪚', 'label': LocaleKeys.carpentry.tr()},
    {'key': 'loading', 'emoji': '📦', 'label': LocaleKeys.loading.tr()},
    {'key': 'cooking', 'emoji': '🍳', 'label': LocaleKeys.cooking.tr()},
    {'key': 'driving', 'emoji': '🚗', 'label': LocaleKeys.driving.tr()},
    {'key': 'security', 'emoji': '🛡️', 'label': LocaleKeys.security.tr()},
    {'key': 'other', 'emoji': 'logo', 'label': LocaleKeys.otherText.tr()},
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _razorpay.clear();
    _descCtrl.dispose();
    _wageCtrl.dispose();
    _addressCtrl.dispose();
    _villageCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _fetchingLocation = true);
    final pos = await LocationService.getCurrentLocation(context: context);
    if (pos != null && mounted) {
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _fetchingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(LocaleKeys.locationCaptured.tr()),
        backgroundColor: AppColors.success,
      ));
    } else {
      setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
          context: context, initialTime: TimeOfDay.fromDateTime(_dateTime));
      if (time != null && mounted) {
        setState(() => _dateTime =
            DateTime(date.year, date.month, date.day, time.hour, time.minute));
      }
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 50);
    if (images.isNotEmpty) {
      for (var img in images) {
        if (!mounted) return;
        setState(() => _imagePaths.add(img.path));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(LocaleKeys.pleaseGetGps.tr()),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    _initiatePayment();
  }

  Future<void> _initiatePayment() async {
    final List<String> uploadedUrls = [];

    if (_imagePaths.isNotEmpty) {
      setState(() => _isPublishing = true);

      for (var path in _imagePaths) {
        // If path is already a remote URL (e.g. when editing), keep it as-is
        if (path.startsWith('http://') || path.startsWith('https://')) {
          uploadedUrls.add(path);
          continue;
        }
        final res = await SecureUploadService.uploadImage(
            filePath: path, uploadType: 'job_site');
        if (res['success'] == true) {
          uploadedUrls.add(res['url']);
        }
      }
    }

    if (!mounted) return;
    setState(() => _isPublishing = true);

    final jobData = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'category': _category,
      'requiredSkills': _selectedSkills,
      'wage': double.parse(_wageCtrl.text),
      'wageType': _wageType,
      'maxWorkers': _jobType == 'driver' ? 1 : _maxWorkers,
      'location': {
        'type': 'Point',
        'coordinates': [_lng ?? 0.0, _lat ?? 0.0],
        'address': _addressCtrl.text.trim(),
        'village': _villageCtrl.text.trim(),
      },
      'dateTime': _dateTime.toIso8601String(),
      'durationValue': int.tryParse(_durationCtrl.text) ?? 1,
      'durationUnit': _durationUnit,
      'isUrgent': _isUrgent,
      'jobType': _jobType,
      if (_jobType == 'driver')
        'driverRequirements': {
          'vehicleType': _driverVehicleType,
          'mustHaveOwnVehicle': _driverMustOwnVehicle,
          'outstationRequired': _driverOutstation,
          'licenseType': _driverLicenseType,
          'minExperienceYears': _driverMinExperienceYears,
          'nightShift': _driverNightShift,
          'fuelAllowance': _driverFuelAllowance,
          'tollAllowance': _driverTollAllowance,
          'accommodation': _driverAccommodation,
          'uniformProvided': _driverUniformProvided,
          'shiftTiming': _driverShiftTiming,
          'tripType': _driverTripType,
        },
      'images': uploadedUrls,
    };

    try {
      if (widget.existingJob != null) {
        await ref.read(jobProvider.notifier).updateJob(widget.existingJob!.id, jobData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${LocaleKeys.jobPublished.tr()} (Updated)'),
            backgroundColor: AppColors.success,
          ));
          context.pop();
        }
      } else {
        if (_isUrgent) {
          setState(() => _isPublishing = false); // Hide loader while sheet is open
          await _fetchWallet(); // Fetch fresh balance
          if (mounted) _showPaymentBottomSheet(jobData);
        } else {
          final result = await ref.read(jobProvider.notifier).postJob(jobData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(LocaleKeys.jobPublished.tr()),
              backgroundColor: AppColors.success,
            ));
            context.pop();
          }
        }
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    } 
    // removed finally block resetting _isPublishing to false for urgent orders 
    // to prevent user from tapping submit again while razorpay is active
  }

  void _showPaymentBottomSheet(Map<String, dynamic> jobData) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final hasEnoughCredits = _creditsBalance >= 1;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Payment Method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Urgent job fee: 1 posting credit', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 24),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: hasEnoughCredits ? AppColors.success.withOpacity(0.1) : Colors.grey.shade200,
                leading: Icon(Icons.confirmation_number_rounded, color: hasEnoughCredits ? AppColors.success : Colors.grey),
                title: const Text('Use Job Credits'),
                subtitle: Text('Credits available: $_creditsBalance'),
                trailing: hasEnoughCredits ? null : TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    // Route to credits screen
                  },
                  child: const Text('Buy Credits', style: TextStyle(color: AppColors.primary)),
                ),
                onTap: hasEnoughCredits ? () {
                  Navigator.pop(ctx);
                  _submitJobWithPaymentMethod(jobData, 'credits');
                } : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: AppColors.primary.withOpacity(0.1),
                leading: const Icon(Icons.payment, color: AppColors.primary),
                title: const Text('Pay via Razorpay'),
                subtitle: const Text('UPI, Cards, Netbanking'),
                onTap: () {
                  Navigator.pop(ctx);
                  _submitJobWithPaymentMethod(jobData, 'razorpay');
                },
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _submitJobWithPaymentMethod(Map<String, dynamic> jobData, String paymentMethod) async {
    setState(() => _isPublishing = true);
    jobData['paymentMethod'] = paymentMethod;
    try {
      final result = await ref.read(jobProvider.notifier).postJob(jobData);
      
      if (paymentMethod == 'credits') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('1 credit used. Urgent notifications sent.'),
            backgroundColor: AppColors.success,
          ));
          context.pop();
        }
      } else {
        if (result['isUrgentOrder'] == true) {
          _handleRazorpayPayment(result);
        }
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _handleRazorpayPayment(Map<String, dynamic> result) {
    if (!mounted) return;
    _currentRazorpayOrderId = result['order_id'];
    _currentJobId = result['job']?.id;
    
    final user = ref.read(authProvider).user;
    
    var options = {
      'key': result['razorpay_key_id'],
      'amount': result['amount'],
      'name': 'Kaamkaaz',
      'description': 'Urgent Job Posting Fee',
      'order_id': result['order_id'],
      'prefill': {
        'contact': user?.phone ?? '',
        'email': user?.email ?? ''
      },
      'theme': {
        'color': '#1565C0'
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _showError('Failed to launch Razorpay');
      setState(() => _isPublishing = false);
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_currentJobId == null) return;
    
    try {
      final res = await ApiService.post('${ApiConfig.jobDetail}/$_currentJobId/verify-urgent-payment', {
        'razorpay_payment_id': response.paymentId,
        'razorpay_order_id': response.orderId ?? _currentRazorpayOrderId,
        'razorpay_signature': response.signature,
      });

      if (!mounted) return;
      setState(() => _isPublishing = false);
      
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payment Successful! Urgent notifications sent.'),
          backgroundColor: AppColors.success,
        ));
        context.pop();
      } else {
        _showError(res['message'] ?? 'Payment verification failed');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPublishing = false);
      _showError('Error verifying payment: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isPublishing = false);
    _showError('Payment Failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isPublishing = false);
    _showError('External Wallet Selected: ${response.walletName}');
  }

  Future<void> _pickOnMap() async {
    final ll.LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLocation:
              _lat != null && _lng != null ? ll.LatLng(_lat!, _lng!) : null,
        ),
      ),
    );

    if (result != null) {
      if (!mounted) return;
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
          label: LocaleKeys.retry.tr(),
          textColor: Colors.white,
          onPressed: _submit),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(LocaleKeys.postAJob.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop()),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Job Type Selector ──────────────────────────────────────
              _sectionLabel(LocaleKeys.jobType.tr()),
              const SizedBox(height: 10),
              Row(
                children: [
                  _jobTypeCard('general', '👷', LocaleKeys.generalJob.tr()),
                  const SizedBox(width: 12),
                  _jobTypeCard('driver', '🚗', LocaleKeys.driverJob.tr()),
                ],
              ),
              const SizedBox(height: 20),
              if (_jobType == 'driver') ...[
                _sectionLabel(LocaleKeys.driverRequirements.tr()),
                const SizedBox(height: 12),
                // ── Luxury Driver Requirements Card ─────────────────────
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.driving.withValues(alpha: 0.04),
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.driving.withValues(alpha: 0.18), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.driving.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header strip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.driving.withValues(alpha: 0.08),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.driving,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.drive_eta_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(LocaleKeys.driverRequirements.tr(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    )),
                                Text(LocaleKeys.fillInWhatMatters.tr(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMedium,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Vehicle Type
                            _fieldLabel('🚘  ${LocaleKeys.vehicleTypeReq.tr()}'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _driverVehicleType,
                              hint: Text(LocaleKeys.selectVehicleType.tr()),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              ),
                              items: [
                                {'key': 'Bike', 'label': '🏍️  ${LocaleKeys.bikeMotorcycle.tr()}'},
                                {'key': 'Auto', 'label': '🛺  ${LocaleKeys.autoRickshaw.tr()}'},
                                {'key': 'Car', 'label': '🚗  ${LocaleKeys.car.tr()}'},
                                {'key': 'SUV', 'label': '🚙  ${LocaleKeys.suvMuv.tr()}'},
                                {'key': 'Van', 'label': '🚐  ${LocaleKeys.vanTraveller.tr()}'},
                                {'key': 'Truck', 'label': '🚛  ${LocaleKeys.truck.tr()}'},
                                {'key': 'Bus', 'label': '🚌  ${LocaleKeys.bus.tr()}'},
                                {'key': 'Tractor', 'label': '🚜  ${LocaleKeys.tractor.tr()}'},
                                {'key': 'Any', 'label': '✅  ${LocaleKeys.anyVehicle.tr()}'},
                              ].map((t) => DropdownMenuItem(
                                  value: t['key'],
                                  child: Text(t['label']!, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (v) => setState(() => _driverVehicleType = v),
                            ),
                            const SizedBox(height: 20),

                            // 2. License Type
                            _fieldLabel('📄  ${LocaleKeys.licenseTypeReq.tr()}'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _driverLicenseType,
                              hint: Text(LocaleKeys.selectLicenseType.tr()),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              ),
                              items: [
                                {'key': 'MCWG', 'label': '🏍️  ${LocaleKeys.mcwgMotorcycle.tr()}'},
                                {'key': 'LMV', 'label': '🚗  ${LocaleKeys.lmvCar.tr()}'},
                                {'key': 'LMV-TR', 'label': '🚐  ${LocaleKeys.lmvTrTaxi.tr()}'},
                                {'key': 'HMV', 'label': '🚛  ${LocaleKeys.hmvTruck.tr()}'},
                                {'key': 'HTV', 'label': '🚌  ${LocaleKeys.htvBus.tr()}'},
                                {'key': 'Any', 'label': '✅  ${LocaleKeys.anyValidLicense.tr()}'},
                                {'key': 'None', 'label': '❌  ${LocaleKeys.noLicenseReq.tr()}'},
                              ].map((t) => DropdownMenuItem(
                                  value: t['key'],
                                  child: Text(t['label']!, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (v) => setState(() => _driverLicenseType = v),
                            ),
                            const SizedBox(height: 20),

                            // 3. Trip Type chips
                            _fieldLabel('🗺️  ${LocaleKeys.tripTypeReq.tr()}'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                {'key': 'local', 'label': '🏙️ Local', 'desc': LocaleKeys.withinCity.tr()},
                                {'key': 'intercity', 'label': '🛣️ Intercity', 'desc': LocaleKeys.betweenCities.tr()},
                                {'key': 'outstation', 'label': '🗺️ Outstation', 'desc': LocaleKeys.longDistance.tr()},
                              ].map((t) {
                                final sel = _driverTripType == t['key'];
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _driverTripType = t['key']),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: sel ? AppColors.driving : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: sel ? AppColors.driving : AppColors.border,
                                          width: sel ? 2 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(t['label']!,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: sel ? Colors.white : AppColors.textDark,
                                              )),
                                          Text(t['desc']!,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: sel ? Colors.white70 : AppColors.textLight,
                                              )),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (_jobType == 'general') ...[
                _section(LocaleKeys.jobCategory.tr()),
                const SizedBox(height: 10),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final isSelected = _category == cat['key'];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _category = cat['key']!);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 10),
                          width: 72,
                          decoration: BoxDecoration(
                            color:
                                isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              cat['emoji'] == 'logo'
                                  ? const BrandLogo(size: 24, borderRadius: 6)
                                  : Text(cat['emoji']!,
                                      style: const TextStyle(fontSize: 24)),
                              const SizedBox(height: 4),
                              Text(cat['label']!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textMedium,
                                  ),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _section(LocaleKeys.jobTitle.tr()),
              const SizedBox(height: 8),
              VoiceTextField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: LocaleKeys.jobTitle.tr()),
                validator: (v) => (v == null || v.isEmpty)
                    ? LocaleKeys.titleRequired.tr()
                    : null,
              ),
              const SizedBox(height: 16),
              _section(LocaleKeys.description.tr()),
              const SizedBox(height: 8),
              VoiceTextField(
                controller: _descCtrl,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration:
                    InputDecoration(hintText: LocaleKeys.description.tr()),
                validator: (v) => (v == null || v.isEmpty)
                    ? LocaleKeys.descriptionRequired.tr()
                    : null,
              ),
              const SizedBox(height: 16),
if (_jobType == 'general') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppColors.cardShadow),
                child: Row(
                  children: [
                    const Text('👥', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(LocaleKeys.workersNeeded.tr(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Text(LocaleKeys.workersNeededDesc.tr(),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMedium)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _maxWorkers > 1
                              ? () => setState(() => _maxWorkers--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          color: AppColors.primary,
                        ),
                        Text(
                          '$_maxWorkers',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _maxWorkers++),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _section(LocaleKeys.wage.tr()),
                        const SizedBox(height: 8),
                        VoiceTextField(
                          controller: _wageCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              hintText: '500', prefixText: '₹ '),
                          validator: (v) => (v == null || v.isEmpty)
                              ? LocaleKeys.required.tr()
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _section(LocaleKeys.per.tr()),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _wageType,
                          decoration: const InputDecoration(),
                          items: [
                            {'key': 'hourly', 'label': LocaleKeys.hourly.tr()},
                            {'key': 'daily', 'label': LocaleKeys.daily.tr()},
                            {'key': 'weekly', 'label': LocaleKeys.weekly.tr()},
                            {'key': 'fixed', 'label': LocaleKeys.fixed.tr()},
                          ]
                              .map((t) => DropdownMenuItem(
                                  value: t['key'],
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(t['label']!,
                                        style: const TextStyle(fontSize: 14)),
                                  )))
                              .toList(),
                          onChanged: (v) {
                            setState(() => _wageType = v!);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
if (_jobType == 'general') ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _section(LocaleKeys.duration.tr()),
                        const SizedBox(height: 8),
                        VoiceTextField(
                          controller: _durationCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '1'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _section(LocaleKeys.unit.tr()),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _durationUnit,
                          decoration: const InputDecoration(),
                          items: [
                            {'key': 'hours', 'label': LocaleKeys.hours.tr()},
                            {'key': 'days', 'label': LocaleKeys.days.tr()},
                            {'key': 'weeks', 'label': LocaleKeys.weeks.tr()},
                            {'key': 'months', 'label': LocaleKeys.months.tr()},
                          ]
                              .map((t) => DropdownMenuItem(
                                  value: t['key'],
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(t['label']!,
                                        style: const TextStyle(fontSize: 14)),
                                  )))
                              .toList(),
                          onChanged: (v) {
                            setState(() => _durationUnit = v!);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ],
              const SizedBox(height: 16),
              _section(LocaleKeys.startDateAndTime.tr()),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_dateTime.day}/${_dateTime.month}/${_dateTime.year}  ${_dateTime.hour.toString().padLeft(2, '0')}:${_dateTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.edit_rounded,
                          size: 16, color: AppColors.textLight),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _section(LocaleKeys.location.tr()),
              const SizedBox(height: 8),
              VoiceTextField(
                controller: _addressCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: LocaleKeys.streetAddress.tr(),
                  prefixIcon: const Icon(Icons.location_on_rounded),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? LocaleKeys.addressRequired.tr()
                    : null,
              ),
              const SizedBox(height: 8),
              VoiceTextField(
                controller: _villageCtrl,
                textCapitalization: TextCapitalization.words,
                decoration:
                    InputDecoration(hintText: LocaleKeys.villageCity.tr()),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _fetchingLocation ? null : _getLocation,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _fetchingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location_rounded),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _lat != null
                                  ? '✅ ${LocaleKeys.gpsSet.tr()}'
                                  : LocaleKeys.getGps.tr(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickOnMap,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(color: AppColors.secondary),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.map_rounded),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              LocaleKeys.pickOnMap.tr(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_jobType == 'general') ...[const SizedBox(height: 16),
              _sectionLabel(LocaleKeys.requiredSkills.tr()),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _currentSkillsList.map((s) {
                  final selected = _selectedSkills.contains(s);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selected
                            ? _selectedSkills.remove(s)
                            : _selectedSkills.add(s);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2))
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selected)
                            const Icon(Icons.check_rounded,
                                size: 14, color: Colors.white),
                          if (selected) const SizedBox(width: 4),
                          Text(s,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textMedium,
                              )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              ],
              const SizedBox(height: 16),
if (_jobType == 'general') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(LocaleKeys.optional.tr().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.info,
                                letterSpacing: 1,
                              )),
                        ),
                        const SizedBox(width: 8),
                        Text('📸 ${LocaleKeys.sitePhotos.tr()}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      LocaleKeys.sitePhotosDesc.tr(),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 14),
                    // Image grid + add button
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        // Existing image thumbnails
                        ..._imagePaths.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final img = entry.value;
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(img),
                                  width: 88,
                                  height: 88,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 88,
                                    height: 88,
                                    color: AppColors.inputBg,
                                    child: const Icon(
                                        Icons.broken_image_rounded,
                                        color: AppColors.textLight),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _imagePaths.removeAt(idx);
                                    });
                                  },
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: AppColors.danger,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        if (_imagePaths.length < 5)
                          GestureDetector(
                            onTap: _pickImages,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.4),
                                  width: 1.5,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded,
                                      color: AppColors.primary
                                          .withValues(alpha: 0.8),
                                      size: 28),
                                  const SizedBox(height: 4),
                                  Text(
                                    _imagePaths.isEmpty
                                        ? LocaleKeys.addPhoto.tr()
                                        : LocaleKeys.addMore.tr(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_imagePaths.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.photo_library_rounded,
                                size: 14, color: AppColors.textLight),
                            const SizedBox(width: 4),
                            Text(
                                LocaleKeys.photosAdded
                                    .tr(args: [_imagePaths.length.toString()]),
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textLight)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _imagePaths.clear();
                                });
                              },
                              child: Text(LocaleKeys.clearAll.tr(),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    boxShadow: AppColors.cardShadow),
                child: Row(
                  children: [
                    const Text('🚨', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mark as Urgent (₹9 Fee)',
                              style:
                                  TextStyle(fontWeight: FontWeight.w800, color: Colors.red)),
                          const Text('Sends loud alarm notification to workers within 50km. A fee of ₹9 applies.',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textDark)),
                        ],
                      ),
                    ),
                    Switch(
                        value: _isUrgent,
                        onChanged: (v) {
                          setState(() => _isUrgent = v);
                        },
                        activeColor: Colors.red),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed:
                    (_isPublishing || _fetchingLocation) ? null : _submit,
                child: _isPublishing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2)),
                            const SizedBox(width: 12),
                            Text(LocaleKeys.publishing.tr()),
                          ])
                    : Text(_isUrgent ? 'Pay & Boost Job (₹9)' : LocaleKeys.postJobButton.tr()),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _jobTypeCard(String type, String emoji, String title) {
    final isSelected = _jobType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _jobType = type;
            _selectedSkills.clear();
            if (type == 'driver') {
              _category = 'driving';
            } else if (_category == 'driving') {
              _category = 'construction';
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.driving : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isSelected ? AppColors.driving : AppColors.border,
                width: 2),
            boxShadow:
                isSelected ? AppColors.primaryShadow : AppColors.cardShadow,
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => _sectionLabel(title);

  Widget _sectionLabel(String title) => Text(title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textMedium,
        letterSpacing: 0.3,
      ));

  Widget _fieldLabel(String title) => Text(title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ));
}
