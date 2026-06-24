import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart';
import '../../services/api_service.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/error_handler.dart';

class KycStatusScreen extends ConsumerStatefulWidget {
  const KycStatusScreen({super.key});

  @override
  ConsumerState<KycStatusScreen> createState() => _KycStatusScreenState();
}

class _KycStatusScreenState extends ConsumerState<KycStatusScreen> {
  final _aadhaarCtrl = TextEditingController();
  final _panCtrl = TextEditingController();

  String? _frontImageUrl;
  String? _backImageUrl;
  String? _panImageUrl;
  bool _isUploading = false;

  @override
  void dispose() {
    _aadhaarCtrl.dispose();
    _panCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(String type) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final url = await CloudinaryService.uploadImageDirectly(image.path);
      if (url != null) {
        setState(() {
          if (type == 'front') _frontImageUrl = url;
          else if (type == 'back') _backImageUrl = url;
          else if (type == 'pan') _panImageUrl = url;
        });
      } else {
        if (mounted) ErrorHandler.showSnackbar(context, 'kyc_upload_failed'.tr());
      }
    } catch (e) {
      if (mounted) ErrorHandler.showSnackbar(context, ErrorHandler.getMessage(e));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _submitKyc() async {
    if (_aadhaarCtrl.text.isEmpty || _frontImageUrl == null || _backImageUrl == null) {
      ErrorHandler.showSnackbar(context, 'kyc_validation_error'.tr());
      return;
    }

    setState(() => _isUploading = true);
    try {
      final res = await ApiService.post('/kyc/submit', {
        'aadhaarNumber': _aadhaarCtrl.text,
        'panNumber': _panCtrl.text,
        'frontImageUrl': _frontImageUrl,
        'backImageUrl': _backImageUrl,
        'panImageUrl': _panImageUrl,
      });

      if (res['success'] == true) {
        ref.read(authProvider.notifier).refreshUser();
        if (mounted) {
          ErrorHandler.showSuccessSnackbar(context, 'KYC Submitted!');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) ErrorHandler.showSnackbar(context, ErrorHandler.getMessage(e));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final status = user.kycStatus;
    
    return Scaffold(
      appBar: AppBar(title: Text('kyc_verification_title'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(status, user.kycNote),
            const SizedBox(height: 24),
            if (status == 'pending')
              const Text('Your documents are under review.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            
            if (status == 'rejected' || status == 'not_submitted') ...[
              const Text('Submit Documents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _aadhaarCtrl,
                decoration: const InputDecoration(labelText: 'Aadhaar Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildImageUploader('Aadhaar Front', 'front', _frontImageUrl),
              const SizedBox(height: 16),
              _buildImageUploader('Aadhaar Back', 'back', _backImageUrl),
              const SizedBox(height: 16),
              TextField(
                controller: _panCtrl,
                decoration: const InputDecoration(labelText: 'PAN Number (Optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              _buildImageUploader('PAN Card (Optional)', 'pan', _panImageUrl),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUploading ? null : _submitKyc,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : Text('kyc_submit_button'.tr()),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploader(String label, String type, String? currentUrl) {
    return InkWell(
      onTap: () => _pickAndUploadImage(type),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: currentUrl != null
            ? Image.network(currentUrl, fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_file, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text('Upload $label'),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusCard(String status, String? note) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case 'approved': color = Colors.green; icon = Icons.check_circle; text = 'kyc_status_approved'.tr(); break;
      case 'pending': color = Colors.orange; icon = Icons.access_time; text = 'kyc_status_pending'.tr(); break;
      case 'rejected': color = Colors.red; icon = Icons.error; text = 'kyc_status_rejected'.tr(); break;
      default: color = Colors.grey; icon = Icons.info; text = 'Not Submitted';
    }

    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: 8),
            Text(text, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            if (status == 'rejected' && note != null && note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Reason: $note', style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
