import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../components/toast.dart';
import '../components/error_state.dart';

/// Gestionnaire d'erreurs amélioré avec retry et meilleure UX
class ErrorHandlerV2 {
  /// Affiche une erreur avec toast et option de retry
  static void showError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    bool showToast = true,
  }) {
    String message = 'An error occurred';
    ToastType toastType = ToastType.error;

    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          message = 'Session expired. Please login again.';
          toastType = ToastType.warning;
          // Auto-redirect to login après 2 secondes
          Future.delayed(const Duration(seconds: 2), () {
            // Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          });
          break;
        case 403:
          message = 'Access denied. You don\'t have permission.';
          toastType = ToastType.warning;
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
      message = error.toString().replaceFirst('Exception: ', '');
    }

    if (showToast) {
      Toast.show(context, message: message, type: toastType);
    }
  }

  /// Gère un appel API avec retry automatique et meilleure UX
  static Future<T?> handleApiCall<T>(
    BuildContext context,
    Future<T> Function() apiCall, {
    bool showLoading = true,
    bool showErrorToast = true,
    int maxRetries = 0,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        return await apiCall();
      } on ApiException catch (e) {
        if (e.statusCode == 401 || e.statusCode == 403) {
          showError(context, e, showToast: showErrorToast);
          return null;
        }

        // Si on a encore des tentatives, retry
        if (attempts < maxRetries) {
          attempts++;
          await Future.delayed(retryDelay);
          continue;
        }

        showError(context, e, showToast: showErrorToast);
        return null;
      } catch (e) {
        if (attempts < maxRetries) {
          attempts++;
          await Future.delayed(retryDelay);
          continue;
        }

        showError(context, e, showToast: showErrorToast);
        return null;
      }
    }

    return null;
  }

  /// Widget pour afficher un état d'erreur avec retry
  static Widget buildErrorWidget(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    String? customTitle,
    String? customMessage,
  }) {
    String title = customTitle ?? 'Something went wrong';
    String? message = customMessage;

    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          title = 'Session Expired';
          message = 'Please login again to continue.';
          break;
        case 403:
          title = 'Access Denied';
          message = 'You don\'t have permission to access this resource.';
          break;
        case 404:
          title = 'Not Found';
          message = 'The requested resource could not be found.';
          break;
        case 500:
          title = 'Server Error';
          message = 'Something went wrong on our end. Please try again later.';
          break;
        default:
          message = error.message;
      }
    }

    return ErrorState(
      title: title,
      message: message ?? customMessage,
      onRetry: onRetry,
    );
  }
}
