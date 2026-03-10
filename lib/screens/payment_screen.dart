import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../core/constants.dart';
import '../models/event_model.dart';
import '../services/payment_service.dart';
import '../services/supabase_service.dart';
import '../utils/device_helper.dart';

enum _PaymentState { idle, processing, success, failed }

class PaymentScreen extends StatefulWidget {
  final EventModel event;

  const PaymentScreen({super.key, required this.event});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  _PaymentState _state = _PaymentState.idle;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    PaymentService.instance.initialize();
  }

  @override
  void dispose() {
    PaymentService.instance.dispose();
    super.dispose();
  }

  Future<void> _startPayment() async {
    setState(() => _state = _PaymentState.processing);

    final deviceId = await DeviceHelper.getDeviceId();

    PaymentService.instance.openCheckout(
      eventId: widget.event.id,
      eventTitle: widget.event.title,
      deviceId: deviceId,
      onSuccess: (resp) async {
        // Mark user as subscribed in Supabase
        await SupabaseService.instance.setSubscribed(deviceId, value: true);
        if (mounted) setState(() => _state = _PaymentState.success);
      },
      onFailure: (resp) {
        if (mounted) {
          setState(() {
            _state = _PaymentState.failed;
            _errorMessage = resp.message ?? 'Payment failed. Please try again.';
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(AppStrings.subscription, style: AppTextStyles.heading3),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case _PaymentState.idle:
        return _IdleView(event: widget.event, onPay: _startPayment);
      case _PaymentState.processing:
        return const _ProcessingView();
      case _PaymentState.success:
        return _SuccessView(onDone: () => context.pop());
      case _PaymentState.failed:
        return _FailedView(
          message: _errorMessage,
          onRetry: () => setState(() => _state = _PaymentState.idle),
        );
    }
  }
}

class _IdleView extends StatelessWidget {
  final EventModel event;
  final VoidCallback onPay;

  const _IdleView({required this.event, required this.onPay});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Event banner ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.lock_open_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Event Access', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                    Text(event.title,
                        style: AppTextStyles.heading3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      '₹${event.price} one-time',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        Text('What you get:', style: AppTextStyles.heading3),
        const SizedBox(height: 16),

        ..._benefits.map((b) => _BenefitRow(icon: b.$1, text: b.$2)),

        const Spacer(),

        // ── Pay button ────────────────────────────────────────────────────
        GestureDetector(
          onTap: onPay,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.payment_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text('Pay ₹${event.price} via Razorpay',
                    style: AppTextStyles.button),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Secure payment powered by Razorpay',
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }

  static const _benefits = [
    (Icons.photo_library_rounded, 'Unlock ALL photos in ALL events'),
    (Icons.no_adult_content_rounded, 'No ads – watch and download instantly'),
    (Icons.devices_rounded, 'One-time subscription per device'),
    (Icons.security_rounded, 'Secure payment via Razorpay'),
  ];
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Processing payment…',
              style: AppTextStyles.bodySecondary),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onDone;

  const _SuccessView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          Text('Payment Successful!', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          Text(AppStrings.paymentSuccess,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
            child: const Text('View Photos'),
          ),
        ],
      ),
    );
  }
}

class _FailedView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _FailedView({this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Payment Failed', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          Text(message ?? 'Please try again.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
