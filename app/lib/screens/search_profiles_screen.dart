import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';
import '../utils/app_colors.dart';
import '../models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/locale_keys.g.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class SearchProfilesScreen extends StatefulWidget {
  const SearchProfilesScreen({super.key});

  @override
  State<SearchProfilesScreen> createState() => _SearchProfilesScreenState();
}

class _SearchProfilesScreenState extends State<SearchProfilesScreen> {
  final _searchCtrl = TextEditingController();
  List<UserModel> _results = [];
  bool _isLoading = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        final localeId = context.locale.languageCode == 'hi' ? 'hi_IN' : 'en_US';
        _speech.listen(
          onResult: (val) {
            setState(() {
              _searchCtrl.text = val.recognizedWords;
              if (val.hasConfidenceRating && val.confidence > 0) {
                 _search();
              }
            });
          },
          localeId: localeId,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _search() async {
    if (_searchCtrl.text.trim().isEmpty) return;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _results = [];
    });

    final q = _searchCtrl.text.trim();
    final res = await ApiService.get('${ApiConfig.userSearch}?name=$q');

    if (mounted) {
      if (res['success'] == true && res['data'] != null) {
        if (!mounted) return;
        setState(() {
          _results = (res['data'] as List)
              .map((u) => UserModel.fromJson(u))
              .where((u) => u.role != 'admin')
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(LocaleKeys.searchProfiles.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: VoiceTextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: LocaleKeys.searchByName.tr(),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _listen,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.all(_isListening ? 6 : 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening ? Colors.red.withValues(alpha: 0.2) : Colors.transparent,
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : AppColors.primary,
                          size: _isListening ? 26 : 24,
                        ),
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded,
                            color: AppColors.primary),
                        onPressed: _search),
                  ],
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _search(),
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : _results.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.2),
                            Center(
                              child: Text(
                                  _searchCtrl.text.isEmpty
                                      ? LocaleKeys.search.tr()
                                      : LocaleKeys.noProfilesFound.tr(),
                                  style: const TextStyle(
                                      color: AppColors.textMedium)),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _results.length,
                          itemBuilder: (_, i) {
                            final u = _results[i];
                            return GestureDetector(
                              onTap: () =>
                                  context.push('/public-profile/${u.id}'),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: AppColors.cardShadow),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      backgroundImage: u.profileImage.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              u.profileImage)
                                          : null,
                                      child: u.profileImage.isEmpty
                                          ? Text(u.name[0],
                                              style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold))
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(u.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15)),
                                          Wrap(
                                            spacing: 6,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(u.role.toUpperCase(),
                                                  style: const TextStyle(
                                                      color:
                                                          AppColors.textLight,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                              if (u.verifiedSkills
                                                  .isNotEmpty) ...[
                                                const SizedBox(width: 4),
                                                const Icon(
                                                    Icons.verified_rounded,
                                                    size: 12,
                                                    color: AppColors.success),
                                                const SizedBox(width: 2),
                                                Text(
                                                    LocaleKeys
                                                        .verifiedBadgesCount
                                                        .tr(args: [
                                                      u.verifiedSkills.length
                                                          .toString()
                                                    ]),
                                                    style: const TextStyle(
                                                        color:
                                                            AppColors.success,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w800)),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded,
                                        color: AppColors.textLight),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
