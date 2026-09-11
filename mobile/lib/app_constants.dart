import 'package:flutter/material.dart';

/// Shared color constants for the app.
class AppColors {
  static const Color primary = Color(0xFF2C6E49);
  static const Color accent = Color(0xFF4C956C);
  static const Color success = Color(0xFF4CAF50);
  static const Color warn = Color(0xFFF6AE2D);
  static const Color background = Color(0xFFF5F5F5);
}

/// Demo coordinates used for testing the map without a GPS device.
class DemoLocation {
  static const double latitude = 40.7128;
  static const double longitude = -74.0060;
}

/// Shared helpers for job status rendering.
Color jobStatusColor(String status) {
  switch (status) {
    case 'matched':
      return Colors.blue;
    case 'accepted':
      return Colors.orange;
    case 'en_route':
      return Colors.teal;
    case 'in_progress':
      return Colors.purple;
    case 'completed':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String jobStatusLabel(String status) {
  switch (status) {
    case 'matched':
      return 'New Offer';
    case 'accepted':
      return 'Accepted';
    case 'en_route':
      return 'On the Way';
    case 'in_progress':
      return 'In Progress';
    case 'completed':
      return 'Completed';
    case 'cancelled':
      return 'Cancelled';
    default:
      return status;
  }
}