// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uddoktapay/controllers/payment_controller.dart';
import 'package:uddoktapay/core/services/api_services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final String paymentURL;
  final String redirectURL;
  final String cancelURL;

  const PaymentScreen({
    super.key,
    required this.paymentURL,
    required this.redirectURL,
    required this.cancelURL,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController _webViewController;
  final PaymentController controller = Get.put(PaymentController());

  /// Whether we're currently loading the initial payment page.
  final ValueNotifier<bool> _isPageLoading = ValueNotifier(true);

  /// Whether payment verification is in progress after redirect.
  final ValueNotifier<bool> _isVerifying = ValueNotifier(false);

  @override
  void dispose() {
    _isPageLoading.dispose();
    _isVerifying.dispose();
    super.dispose();
  }

  @override
  void initState() {
    debugPrint('🔗 Redirect URL (domain): ${widget.redirectURL}');
    debugPrint('🔗 Cancel URL: ${widget.cancelURL}');

    super.initState();

    // Clean redirect/cancel for matching
    final cleanRedirect = widget.redirectURL
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/+$'), '');

    final cleanCancelPath = Uri.parse(widget.cancelURL).path;

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            _isPageLoading.value = true;
          },
          onPageFinished: (_) {
            _isPageLoading.value = false;
          },
          onNavigationRequest: (NavigationRequest request) async {
            debugPrint('🌐 Navigation: ${request.url}');

            final uri = Uri.parse(request.url);
            final invoiceId = uri.queryParameters['invoice_id'];

            // ─── CANCEL DETECTION ───
            // Must check cancel BEFORE redirect because cancel URL path
            // may share the same host as redirect.
            // Cancel URL: https://domain.com/checkout/cancel
            if (cleanCancelPath.isNotEmpty && uri.path == cleanCancelPath) {
              debugPrint('❌ Cancel detected: ${request.url}');
              controller.isPaymentVerifying.value = false;
              if (context.mounted) Navigator.pop(context);
              return NavigationDecision.prevent;
            }

            // ─── REDIRECT (SUCCESS) DETECTION ───
            // The actual success redirect from UddoktaPay is:
            //   {redirect_url}?invoice_id=XXXXX
            //
            // CRITICAL: We must NOT match on host alone because the
            // payment panel domain and redirect domain may be identical
            // (e.g. both are shirahsoft.paymently.io).
            //
            // Safe detection: URL must have a non-empty invoice_id param
            // AND must NOT be a checkout/payment processing page.
            final bool hasInvoiceId = invoiceId != null && invoiceId.isNotEmpty;

            final bool isCheckoutPage = uri.path.contains('/checkout/') ||
                uri.path.contains('/payment/');

            final bool hostMatchesRedirect = uri.host == cleanRedirect ||
                uri.host.endsWith('.$cleanRedirect');

            final bool isRedirect =
                hasInvoiceId && hostMatchesRedirect && !isCheckoutPage;

            if (isRedirect) {
              _isVerifying.value = true;
              controller.isPaymentVerifying.value = true;

              debugPrint('✅ Redirect detected! Invoice ID: $invoiceId');

              try {
                final response =
                    await ApiServices.verifyPayment(invoiceId, context);

                controller.isPaymentVerifying.value = false;
                _isVerifying.value = false;

                if (context.mounted) {
                  Navigator.pop(context, response);
                }
              } catch (e) {
                debugPrint('❌ Verify error: $e');
                controller.isPaymentVerifying.value = false;
                _isVerifying.value = false;

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }

              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentURL));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final shimmerBase =
        isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF0F0F0);
    final shimmerHighlight =
        isDark ? const Color(0xFF2A2A3C) : const Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // ─── WebView ───
            WebViewWidget(controller: _webViewController),

            // ─── Page Loading Overlay (shimmer-style) ───
            ValueListenableBuilder<bool>(
              valueListenable: _isPageLoading,
              builder: (_, isLoading, __) {
                if (!isLoading) return const SizedBox.shrink();
                return _PaymentLoadingOverlay(
                  bgColor: bgColor,
                  shimmerBase: shimmerBase,
                  shimmerHighlight: shimmerHighlight,
                );
              },
            ),

            // ─── Verifying Overlay ───
            ValueListenableBuilder<bool>(
              valueListenable: _isVerifying,
              builder: (_, isVerifying, __) {
                if (!isVerifying) return const SizedBox.shrink();
                return _PaymentVerifyingOverlay(isDark: isDark);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer-style loading while payment page loads
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentLoadingOverlay extends StatefulWidget {
  final Color bgColor;
  final Color shimmerBase;
  final Color shimmerHighlight;

  const _PaymentLoadingOverlay({
    required this.bgColor,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  @override
  State<_PaymentLoadingOverlay> createState() => _PaymentLoadingOverlayState();
}

class _PaymentLoadingOverlayState extends State<_PaymentLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.bgColor,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Logo placeholder
                Center(
                  child: _shimmerBox(80, 80, isCircle: true),
                ),
                const SizedBox(height: 24),
                // Title placeholder
                Center(child: _shimmerBox(200, 20)),
                const SizedBox(height: 12),
                Center(child: _shimmerBox(140, 14)),
                const SizedBox(height: 32),
                // Payment methods placeholder
                _shimmerBox(double.infinity, 48, radius: 12),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _shimmerBox(double.infinity, 80, radius: 12)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _shimmerBox(double.infinity, 80, radius: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _shimmerBox(double.infinity, 80, radius: 12)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _shimmerBox(double.infinity, 80, radius: 12)),
                  ],
                ),
                const Spacer(),
                // Bottom button placeholder
                _shimmerBox(double.infinity, 52, radius: 26),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _shimmerBox(double width, double height,
      {double radius = 8, bool isCircle = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            widget.shimmerBase,
            widget.shimmerHighlight,
            widget.shimmerBase,
          ],
          stops: [
            (_animation.value - 0.3).clamp(0.0, 1.0),
            _animation.value.clamp(0.0, 1.0),
            (_animation.value + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Verifying overlay — shown while verifyPayment API call runs
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentVerifyingOverlay extends StatelessWidget {
  final bool isDark;
  const _PaymentVerifyingOverlay({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark
          ? Colors.black.withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? Colors.white : const Color(0xFF4B68FF),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Verifying Payment...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we confirm your transaction',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF6C757D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
