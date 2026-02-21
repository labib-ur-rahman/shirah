class UddoktapayCredentials {
  final String panelURL;
  final String apiKey;
  final String redirectURL;

  /// Optional webhook URL for UddoktaPay IPN notifications.
  /// When set, UddoktaPay will send payment status updates to this URL
  /// when admin clicks "SEND WEBHOOK REQUEST" in the dashboard.
  final String? webhookUrl;

  UddoktapayCredentials({
    required this.apiKey,
    required this.panelURL,
    required this.redirectURL,
    this.webhookUrl,
  });
}
