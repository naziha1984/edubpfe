import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';

class ErrorHandler {
  static void showError(BuildContext context, dynamic error) {
    String message = 'An error occurred';
    Color backgroundColor = EduBridgeColors.error;

    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          message = 'Unauthorized. Please login again.';
          backgroundColor = EduBridgeColors.warning;
          break;
        case 403:
          message = 'Access denied. You don\'t have permission.';
          backgroundColor = EduBridgeColors.warning;
          break;
        case 404:
          message = 'Resource not found.';
          break;
        case 500:
          message = 'Server error. Please try again later.';
          break;
        default:
          message = error.message;
      }
    } else if (error is Exception) {
      message = error.toString();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static Future<T?> handleApiCall<T>(
    BuildContext context,
    Future<T> Function() apiCall,
  ) async {
    try {
      return await apiCall();
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        // Handle authentication errors
        showError(context, e);
        // Optionally navigate to login
        // Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        showError(context, e);
      }
      return null;
    } catch (e) {
      showError(context, e);
      return null;
    }
  }
}
