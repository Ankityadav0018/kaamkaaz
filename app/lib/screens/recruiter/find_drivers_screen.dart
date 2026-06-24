import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../l10n/locale_keys.g.dart';
import '../../widgets/driver_card_widget.dart';

class FindDriversScreen extends ConsumerStatefulWidget {
  const FindDriversScreen({super.key});

  @override
  ConsumerState<FindDriversScreen> createState() => _FindDriversScreenState();
}

class _FindDriversScreenState extends ConsumerState<FindDriversScreen> {
  List<dynamic> _drivers = [];
  bool _loading = true;
  String? _selectedVehicleType;
  bool _outstationOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    String ep = '/driver/nearby?radius=50';
    if (_selectedVehicleType != null) {
      ep += '&vehicleType=${Uri.encodeComponent(_selectedVehicleType!)}';
    }
    if (_outstationOnly) ep += '&outstation=true';
    final res = await ApiService.get(ep);
    if (mounted) {
      setState(() {
        _drivers = res['data'] ?? [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(LocaleKeys.findDrivers.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          )
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                // Vehicle type filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(LocaleKeys.all.tr(), null),
                      _filterChip(LocaleKeys.carSedan.tr(), 'Car / Sedan'),
                      _filterChip(LocaleKeys.suvMuv.tr(), 'SUV / MUV'),
                      _filterChip(LocaleKeys.miniBus.tr(),
                          'Mini Bus / Tempo Traveller'),
                      _filterChip(LocaleKeys.bus.tr(), 'Bus'),
                      _filterChip(
                          LocaleKeys.truckHeavy.tr(), 'Truck / Heavy Vehicle'),
                      _filterChip(
                          LocaleKeys.motorcycle.tr(), 'Motorcycle / Bike'),
                      _filterChip(LocaleKeys.tractor.tr(), 'Tractor'),
                      _filterChip(LocaleKeys.jcb.tr(), 'JCB / Excavator'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _outstationOnly,
                      onChanged: (v) {
                        setState(() => _outstationOnly = v ?? false);
                        _load();
                      },
                      activeColor: AppColors.primary,
                    ),
                    Text(LocaleKeys.outstationAvailableOnly.tr(),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _drivers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🚗', style: TextStyle(fontSize: 56)),
                            const SizedBox(height: 12),
                            Text(LocaleKeys.noVerifiedDriversFound.tr(),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            Text(LocaleKeys.tryExpandingRadius.tr(),
                                style: const TextStyle(
                                    color: AppColors.textLight)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _drivers.length,
                        itemBuilder: (_, i) => DriverCardWidget(
                          driver: _drivers[i],
                          onTap: () => context
                              .push('/driver/public/${_drivers[i]['_id']}'),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value) {
    final isSelected = _selectedVehicleType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedVehicleType = value);
        _load();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.inputBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textMedium)),
      ),
    );
  }
}
