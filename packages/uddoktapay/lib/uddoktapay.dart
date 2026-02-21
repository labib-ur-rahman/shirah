// ignore_for_file: use_build_context_synchronously

library uddoktapay;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uddoktapay/controllers/payment_controller.dart';
import 'package:uddoktapay/models/customer_model.dart';
import 'package:uddoktapay/models/request_response.dart';
import 'package:uddoktapay/utils/config.dart';
import 'package:uddoktapay/views/payment_screen.dart';
import 'core/services/api_services.dart';
import 'models/credentials.dart';

class UddoktaPay {
  static Future<RequestResponse> createPayment({
    required BuildContext context,
    required CustomerDetails customer,
    UddoktapayCredentials? credentials,
    required String amount,
    Map<String, dynamic>? metadata,
  }) async {
    final controller = Get.put(PaymentController());

    final request = await ApiServices.createPaymentRequest(
      customer: customer,
      amount: amount,
      context: context,
      uddoktapayCredentials: credentials,
      metadata: metadata,
      webhookUrl: credentials?.webhookUrl,
    );

    debugPrint('Request Response: $request');

    final String paymentURL = request['payment_url'];
    debugPrint('Payment URL: $paymentURL');

    // Extract the payment ID from the last segment of the path
    String paymentId = Uri.parse(paymentURL).pathSegments.last;
    controller.paymentID.value = paymentId;
    debugPrint('Payment ID: ${controller.paymentID.value}');

    // --- FIX: Normalize URLs for WebView interception ---
    // redirectURL for WebView must be domain-only (no scheme) so
    // uri.host.contains(redirectURL) works in the NavigationDelegate.
    final String webViewRedirectURL;
    final String webViewCancelURL;

    if (credentials == null) {
      webViewRedirectURL = AppConfig.redirectURL;
      webViewCancelURL = AppConfig.cancelURL;
    } else {
      // Strip scheme for WebView redirect matching
      webViewRedirectURL = credentials.redirectURL
          .replaceAll(RegExp(r'^https?://'), '')
          .replaceAll(RegExp(r'/+$'), '');

      // Normalize panelURL for cancel_url construction
      final baseUrl = credentials.panelURL.replaceAll(RegExp(r'/+$'), '');
      webViewCancelURL = '$baseUrl/checkout/cancel';
    }

    final body = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          paymentURL: request['payment_url'],
          redirectURL: webViewRedirectURL,
          cancelURL: webViewCancelURL,
        ),
      ),
    );

    if (body != null) {
      final response = body as RequestResponse;
      return response;
    }

    return RequestResponse(
      status: ResponseStatus.canceled,
    );
  }
}
