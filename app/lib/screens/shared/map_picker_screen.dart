import '../../l10n/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/app_colors.dart';
import '../../services/location_service.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  const MapPickerScreen({super.key, this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ??
        const LatLng(28.6139, 77.2090); // Default to New Delhi
    if (widget.initialLocation == null) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final pos = await LocationService.getCurrentLocation(context: context);
      if (pos == null) return;

      final newLoc = LatLng(pos.latitude, pos.longitude);

      if (!mounted) return;
      setState(() {
        _selectedLocation = newLoc;
      });
      _mapController.move(newLoc, 15);
    } catch (e) {
      // Ignore errors
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.selectLocationTitle.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedLocation);
            },
            child: Text(LocaleKeys.doneBtn.tr(),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.primary)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation!,
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                if (!mounted) return;
                setState(() {
                  _selectedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                userAgentPackageName: 'com.kaamkaaz.app',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on_rounded,
                          color: AppColors.danger, size: 40),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'my_location',
              backgroundColor: Colors.white,
              onPressed: _getCurrentLocation,
              child: _locating
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : const Icon(Icons.my_location_rounded,
                      color: AppColors.primary),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.cardShadow,
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Tap anywhere on the map to set the job location.',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
