import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/driver_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/api_config.dart';
import '../../utils/app_colors.dart';
import '../../widgets/document_upload_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../l10n/locale_keys.g.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  ConsumerState<DriverProfileScreen> createState() =>
      _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  final _expCtrl = TextEditingController();
  final _ownVehicleRegCtrl = TextEditingController();
  final _picker = ImagePicker();

  List<String> _selectedVehicleTypes = [];
  List<String> _selectedLanguages = [];
  bool _willingToOutstation = false;
  bool _hasOwnVehicle = false;
  String _ownVehicleType = '';

  String? _licenceFrontUrl;
  String? _licenceBackUrl;
  String? _aadhaarUrl;
  String? _rcBookUrl;
  String? _policeVerificationUrl;
  String? _passportPhotoUrl;

  // Upload in-progress trackers
  final Map<String, bool> _uploading = {};

  bool _saving = false;
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _expCtrl.dispose();
    _ownVehicleRegCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    final res = await ApiService.get(ApiConfig.driverProfile);
    if (res['success'] == true && res['data'] != null) {
      final dp = DriverProfileModel.fromJson(res['data']);

      if (!mounted) return;
      setState(() {
        _selectedVehicleTypes = dp.vehicleTypes;
        _selectedLanguages = dp.languages;
        _willingToOutstation = dp.willingToOutstation;
        _hasOwnVehicle = dp.hasOwnVehicle;
        _ownVehicleType = dp.ownVehicleType;
        _expCtrl.text = dp.experienceYears.toString();
        _ownVehicleRegCtrl.text = dp.ownVehicleRegNumber;
        _licenceFrontUrl =
            dp.licenceFrontUrl.isNotEmpty ? dp.licenceFrontUrl : null;
        _licenceBackUrl =
            dp.licenceBackUrl.isNotEmpty ? dp.licenceBackUrl : null;
        _aadhaarUrl = dp.aadhaarUrl.isNotEmpty ? dp.aadhaarUrl : null;
        _rcBookUrl = dp.rcBookUrl.isNotEmpty ? dp.rcBookUrl : null;
        _policeVerificationUrl = dp.policeVerificationUrl.isNotEmpty
            ? dp.policeVerificationUrl
            : null;
        _passportPhotoUrl =
            dp.passportPhotoUrl.isNotEmpty ? dp.passportPhotoUrl : null;
      });
    }
  }

  Future<String?> _uploadToCloudinary(File file, String docKey) async {
    setState(() => _uploading[docKey] = true);
    try {
      final res = await ApiService.postMultipart(
        ApiConfig.uploadDriverDoc,
        {'docType': docKey},
        [file.path],
        fileField: 'document',
      );
      if (res['success'] == true) return res['url'] as String;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading[docKey] = false);
    }
    return null;
  }

  Future<void> _pickAndUpload(String docKey, Function(String) onSuccess) async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (xFile == null) return;
    final url = await _uploadToCloudinary(File(xFile.path), docKey);
    if (url != null) {
      setState(() => onSuccess(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('uploadFailedTryAgain'.tr()),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  Future<void> _save() async {
    // Validate mandatory docs
    if (_licenceFrontUrl == null ||
        _licenceBackUrl == null ||
        _aadhaarUrl == null ||
        _passportPhotoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('uploadAllMandatory'.tr()),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    if (_selectedVehicleTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('selectVehicleType'.tr()),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    setState(() => _saving = true);
    try {
      final res = await ApiService.post(ApiConfig.driverProfile, {
        'vehicleTypes': _selectedVehicleTypes,
        'experienceYears': int.tryParse(_expCtrl.text) ?? 0,
        'languages': _selectedLanguages,
        'willingToOutstation': _willingToOutstation,
        'hasOwnVehicle': _hasOwnVehicle,
        'ownVehicleType': _ownVehicleType,
        'ownVehicleRegNumber': _ownVehicleRegCtrl.text,
        'licenceFrontUrl': _licenceFrontUrl ?? '',
        'licenceBackUrl': _licenceBackUrl ?? '',
        'aadhaarUrl': _aadhaarUrl ?? '',
        'rcBookUrl': _rcBookUrl ?? '',
        'policeVerificationUrl': _policeVerificationUrl ?? '',
        'passportPhotoUrl': _passportPhotoUrl ?? '',
      });

      if (mounted) {
        if (res['success'] == true) {
          ref.read(authProvider.notifier).refreshUser();

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('profileSubmittedMsg'.tr()),
            backgroundColor: AppColors.success,
          ));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['message'] ?? 'Failed to save'),
            backgroundColor: AppColors.danger,
          ));
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Column(
        children: [
          _buildHeader(),
          _buildRejectionBanner(),
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) {
                setState(() => _currentPage = i);
              },
              children: [
                _buildPage1(),
                _buildPage2(),
                _buildPage3(),
              ],
            ),
          ),
          _buildNavButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('driverProfileTitle'.tr(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                        [
                          'Vehicle Details',
                          'Preferences',
                          'KYC Documents'
                        ][_currentPage],
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRejectionBanner() {
    final user = ref.watch(authProvider).user;
    final status = user?.driverProfile?.kycStatus;
    final reason = user?.driverProfile?.kycRejectionReason;

    if (status != 'rejected') return const SizedBox();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.danger, size: 20),
              const SizedBox(width: 8),
              Text('verificationRejected'.tr(),
                  style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Reason: ${reason ?? "Documents unclear. Please check and re-upload."}',
            style: const TextStyle(
                color: AppColors.danger, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(3, (i) {
          final done = i < _currentPage;
          final active = i == _currentPage;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: done || active
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── PAGE 1: Vehicle Details ─────────────────────────────────────────────────

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🚘 Vehicle Types You Can Drive'),
          const SizedBox(height: 4),
          Text('selectAllApply'.tr(),
              style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: DriverProfileModel.kVehicleTypes.length,
            itemBuilder: (_, i) {
              final vt = DriverProfileModel.kVehicleTypes[i];
              final emoji = DriverProfileModel.kVehicleEmojis[i];
              final selected = _selectedVehicleTypes.contains(vt);
              return GestureDetector(
                onTap: () {
                  if (!mounted) return;
                  setState(() {
                    if (selected) {
                      _selectedVehicleTypes.remove(vt);
                    } else {
                      _selectedVehicleTypes.add(vt);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: selected ? 1.5 : 1,
                    ),
                    boxShadow: selected
                        ? AppColors.primaryShadow
                        : AppColors.cardShadow,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              vt,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _sectionTitle('📅 Driving Experience'),
          const SizedBox(height: 8),
          VoiceTextField(
            controller: _expCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'yearsOfExpHint'.tr(),
              suffixText: 'years',
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── PAGE 2: Preferences ─────────────────────────────────────────────────────

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🗣️ Languages You Speak'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DriverProfileModel.kLanguages.map((lang) {
              final selected = _selectedLanguages.contains(lang);
              return GestureDetector(
                onTap: () {
                  if (!mounted) return;
                  setState(() {
                    if (selected) {
                      _selectedLanguages.remove(lang);
                    } else {
                      _selectedLanguages.add(lang);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    lang,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _sectionTitle('✈️ Outstation Availability'),
          const SizedBox(height: 8),
          _toggleCard(
            label: 'willingTravelOutstation'.tr(),
            subLabel: 'Multi-day trips outside your city',
            value: _willingToOutstation,
            onChanged: (v) {
              setState(() => _willingToOutstation = v);
            },
          ),
          const SizedBox(height: 20),
          _sectionTitle('🚘 Own Vehicle'),
          const SizedBox(height: 8),
          _toggleCard(
            label: 'haveOwnVehicle'.tr(),
            subLabel: 'Ideal for self-employed drivers',
            value: _hasOwnVehicle,
            onChanged: (v) {
              setState(() => _hasOwnVehicle = v);
            },
          ),
          if (_hasOwnVehicle) ...[
            const SizedBox(height: 12),
            Text('vehicleTypeLabel'.tr(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DriverProfileModel.kVehicleTypes.map((vt) {
                final selected = _ownVehicleType == vt;
                return GestureDetector(
                  onTap: () {
                    setState(() => _ownVehicleType = vt);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.success : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppColors.success : AppColors.border,
                      ),
                    ),
                    child: Text(
                      vt,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            VoiceTextField(
              controller: _ownVehicleRegCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'vehicleRegHint'.tr(),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── PAGE 3: Documents ───────────────────────────────────────────────────────

  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_rounded, color: AppColors.info, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Upload clear, readable photos. Fields marked * are mandatory.',
                    style: TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('📄 Mandatory Documents'),
          const SizedBox(height: 8),
          DocumentUploadTile(
            label: 'drivingLicenceFront'.tr(),
            uploadedUrl: _licenceFrontUrl,
            isMandatory: true,
            isUploading: _uploading['licenceFront'] == true,
            onTap: () =>
                _pickAndUpload('licenceFront', (url) => _licenceFrontUrl = url),
          ),
          DocumentUploadTile(
            label: 'drivingLicenceBack'.tr(),
            uploadedUrl: _licenceBackUrl,
            isMandatory: true,
            isUploading: _uploading['licenceBack'] == true,
            onTap: () =>
                _pickAndUpload('licenceBack', (url) => _licenceBackUrl = url),
          ),
          DocumentUploadTile(
            label: 'aadhaarCardFront'.tr(),
            uploadedUrl: _aadhaarUrl,
            isMandatory: true,
            isUploading: _uploading['aadhaar'] == true,
            onTap: () => _pickAndUpload('aadhaar', (url) => _aadhaarUrl = url),
          ),
          DocumentUploadTile(
            label: 'passportSizePhoto'.tr(),
            uploadedUrl: _passportPhotoUrl,
            isMandatory: true,
            isUploading: _uploading['passportPhoto'] == true,
            onTap: () => _pickAndUpload(
                'passportPhoto', (url) => _passportPhotoUrl = url),
          ),
          const SizedBox(height: 16),
          _sectionTitle('📄 Optional Documents'),
          const SizedBox(height: 8),
          if (_hasOwnVehicle)
            DocumentUploadTile(
              label: LocaleKeys.vehicleRcBook.tr(),
              uploadedUrl: _rcBookUrl,
              isMandatory: false,
              isUploading: _uploading['rcBook'] == true,
              onTap: () => _pickAndUpload('rcBook', (url) => _rcBookUrl = url),
            ),
          DocumentUploadTile(
            label: LocaleKeys.policeVerificationCert.tr(),
            uploadedUrl: _policeVerificationUrl,
            isMandatory: false,
            isUploading: _uploading['policeVerification'] == true,
            onTap: () => _pickAndUpload(
                'policeVerification', (url) => _policeVerificationUrl = url),
          ),
          const SizedBox(height: 20),
          _buildSubmitButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return _saving
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary))
        : ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.send_rounded, size: 20),
            label: Text('submitVerificationBtn'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
          );
  }

  Widget _buildNavButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration:
          BoxDecoration(color: Colors.white, boxShadow: AppColors.softShadow),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text('backBtn'.tr()),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          if (_currentPage < 2)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text('nextBtn'.tr()),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark),
      );

  Widget _toggleCard({
    required String label,
    required String subLabel,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text(subLabel,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}
