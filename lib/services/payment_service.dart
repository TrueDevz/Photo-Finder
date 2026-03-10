import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../core/config.dart';

/// Handles Razorpay payment for event unlock (₹500 one-time).
class PaymentService {
  PaymentService._();
  static PaymentService? _instance;

  static PaymentService get instance {
    _instance ??= PaymentService._();
    return _instance!;
  }

  Razorpay? _razorpay;

  // ─── Callbacks stored per-call ─────────────────────────────────────────────
  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onFailure;
  Function(ExternalWalletResponse)? _onWallet;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  void initialize() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleFailure);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleWallet);
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  // ─── Payment ───────────────────────────────────────────────────────────────

  /// Opens Razorpay checkout to unlock [eventTitle].
  void openCheckout({
    required String eventId,
    required String eventTitle,
    required String deviceId,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    Function(ExternalWalletResponse)? onWallet,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _onWallet = onWallet;

    final options = <String, dynamic>{
      'key': AppConfig.razorpayKeyId,
      'amount': AppConfig.eventUnlockPrice * 100, // paise
      'name': 'Event Photo Finder',
      'description': 'Unlock: $eventTitle',
      'prefill': {
        'contact': '',
        'email': '',
      },
      'notes': {
        'event_id': eventId,
        'device_id': deviceId,
      },
      'theme': {
        'color': '#6C63FF',
      },
      'currency': 'INR',
      'retry': {
        'enabled': true,
        'max_count': 3,
      },
    };

    try {
      _razorpay?.open(options);
    } catch (e) {
      _onFailure?.call(
        PaymentFailureResponse(0, e.toString(), null),
      );
    }
  }

  // ─── Internal Handlers ─────────────────────────────────────────────────────

  void _handleSuccess(PaymentSuccessResponse response) {
    _onSuccess?.call(response);
    _clearCallbacks();
  }

  void _handleFailure(PaymentFailureResponse response) {
    _onFailure?.call(response);
    _clearCallbacks();
  }

  void _handleWallet(ExternalWalletResponse response) {
    _onWallet?.call(response);
    _clearCallbacks();
  }

  void _clearCallbacks() {
    _onSuccess = null;
    _onFailure = null;
    _onWallet = null;
  }
}
