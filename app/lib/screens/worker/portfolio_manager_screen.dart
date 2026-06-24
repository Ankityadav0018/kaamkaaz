import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class PortfolioManagerScreen extends ConsumerStatefulWidget {
  const PortfolioManagerScreen({super.key});

  @override
  ConsumerState<PortfolioManagerScreen> createState() => _PortfolioManagerScreenState();
}

class _PortfolioManagerScreenState extends ConsumerState<PortfolioManagerScreen> {
  bool _isUploading = false;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddPortfolioBottomSheet(),
    );
  }

  Future<void> _deleteItem(String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('confirmDelete'.tr()),
        content: Text('confirmDeleteWorkItemMsg'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancelBtn'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'deleteBtn'.tr(),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isUploading = true);
      final res = await ref.read(authProvider.notifier).deletePortfolioItem(itemId);
      setState(() => _isUploading = false);

      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('workDeletedSuccess'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to delete work'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isHindi = context.locale.languageCode == 'hi';

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final portfolio = user.portfolio;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('previousWork'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : portfolio.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.workspace_premium_rounded, size: 80, color: AppColors.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'noPreviousWorkAddedYet'.tr(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMedium),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'addPhotosVideosTextDesc'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: AppColors.textLight),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddDialog,
                          icon: const Icon(Icons.add_rounded),
                          label: Text('addWork'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: portfolio.length,
                  itemBuilder: (context, index) {
                    final item = portfolio[index];
                    final description = isHindi
                        ? (item.descriptionHindi.isNotEmpty ? item.descriptionHindi : item.descriptionEnglish)
                        : (item.descriptionEnglish.isNotEmpty ? item.descriptionEnglish : item.descriptionHindi);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.mediaUrl.isNotEmpty)
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: item.mediaType == 'image'
                                      ? CachedNetworkImage(
                                          imageUrl: item.mediaUrl,
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            height: 180,
                                            color: Colors.grey.shade100,
                                            child: const Center(child: CircularProgressIndicator()),
                                          ),
                                          errorWidget: (context, url, error) => const Icon(Icons.error),
                                        )
                                      : Container(
                                          height: 180,
                                          width: double.infinity,
                                          color: Colors.black87,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.video_library_rounded, color: Colors.white, size: 48),
                                              const SizedBox(height: 8),
                                              Text(
                                                'clickToWatchVideo'.tr(),
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                                if (item.mediaType == 'video')
                                  Positioned.fill(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        onTap: () => _launchUrl(item.mediaUrl),
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 32),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (description.isNotEmpty) ...[
                                        Text(
                                          description,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Text(
                                        DateFormat('dd MMM yyyy, hh:mm a').format(item.createdAt.toLocal()),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                                  onPressed: () => _deleteItem(item.id),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: portfolio.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
    );
  }
}

class AddPortfolioBottomSheet extends ConsumerStatefulWidget {
  const AddPortfolioBottomSheet({super.key});

  @override
  ConsumerState<AddPortfolioBottomSheet> createState() => _AddPortfolioBottomSheetState();
}

class _AddPortfolioBottomSheetState extends ConsumerState<AddPortfolioBottomSheet> {
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String _mediaType = 'text'; // 'text', 'image', 'video'
  File? _selectedFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    try {
      if (_mediaType == 'image') {
        final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (file != null) {
          setState(() {
            _selectedFile = File(file.path);
          });
        }
      } else if (_mediaType == 'video') {
        final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
        if (file != null) {
          setState(() {
            _selectedFile = File(file.path);
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('errorPickingFile'.tr()), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mediaType != 'text' && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('pleaseSelectFile'.tr()),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await ref.read(authProvider.notifier).addPortfolioItem(
          description: _descCtrl.text.trim(),
          mediaPath: _selectedFile?.path,
          mediaType: _mediaType,
        );

    setState(() => _isLoading = false);

    if (!mounted) return;
    if (res['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('workAddedSuccess'.tr()),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to add work'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {


    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'uploadWork'.tr(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              // Media Type Selection
              Text(
                'selectType'.tr(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMedium),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _typeOption(icon: Icons.text_fields_rounded, label: 'textOnly'.tr(), value: 'text'),
                  const SizedBox(width: 8),
                  _typeOption(icon: Icons.image_rounded, label: 'photo'.tr(), value: 'image'),
                  const SizedBox(width: 8),
                  _typeOption(icon: Icons.video_library_rounded, label: 'video'.tr(), value: 'video'),
                ],
              ),
              const SizedBox(height: 20),
              // Media Picker Field
              if (_mediaType != 'text') ...[
                InkWell(
                  onTap: _isLoading ? null : _pickMedia,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                    ),
                    child: _selectedFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _mediaType == 'image'
                                ? Image.file(_selectedFile!, fit: BoxFit.cover, width: double.infinity)
                                : Container(
                                    color: Colors.black87,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
                                          const SizedBox(height: 8),
                                          Text(
                                            'videoSelected'.tr(),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _mediaType == 'image' ? Icons.add_photo_alternate_rounded : Icons.video_call_rounded,
                                size: 40,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                  _mediaType == 'image'
                                      ? 'choosePhotoGallery'.tr()
                                      : 'chooseVideoGallery'.tr(),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              // Description
              VoiceTextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'description'.tr(),
                  hintText: 'writeAboutWork'.tr(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (_mediaType == 'text' && (v == null || v.isEmpty)) {
                    return 'pleaseProvideDesc'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('uploadBtn'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeOption({required IconData icon, required String label, required String value}) {
    final isSelected = _mediaType == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _mediaType = value;
            _selectedFile = null;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textMedium),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
