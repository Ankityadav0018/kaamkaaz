import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'logger_service.dart';

class LocationService {
  static Future<Position?> getCurrentLocation({BuildContext? context}) async {
    try {
      LoggerService.i('📍 LocationService: Requesting location...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        LoggerService.w('📍 LocationService: Location services are disabled.');
        _showPermissionDialog(context, 'Location services are disabled. Please enable them in settings to use this feature.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        LoggerService.i('📍 LocationService: Requesting permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          LoggerService.w('📍 LocationService: Permission denied.');
          _showPermissionDialog(context, 'Location permission was denied. We need this to find nearby jobs and send SOS alerts.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        LoggerService.w('📍 LocationService: Permission denied forever.');
        _showPermissionDialog(context, 'Location permission is permanently denied. Please open settings to allow access.', isPermanent: true);
        return null;
      }

      LoggerService.i('📍 LocationService: Fetching current position...');
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      LoggerService.e('📍 LocationService Error', e);
      try {
        LoggerService.i('📍 LocationService: Attempting to get last known position...');
        return await Geolocator.getLastKnownPosition();
      } catch (err) {
        LoggerService.e('📍 LocationService Error (Last Known)', err);
        return null;
      }
    }
  }

  static void _showPermissionDialog(BuildContext? context, String message, {bool isPermanent = false}) {
    if (context == null || !context.mounted) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      action: isPermanent 
          ? SnackBarAction(
              label: 'Settings', 
              onPressed: () => Geolocator.openAppSettings(),
              textColor: Colors.white,
            )
          : null,
    ));
  }
}
