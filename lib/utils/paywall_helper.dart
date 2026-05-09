import 'package:flutter/material.dart';
import '../screens/paywall/paywall_screen.dart';

// Call this from anywhere in the app to show the paywall
Future<void> showPaywall(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false, // user must tap "Not now" or "No thanks"
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.92,
      maxChildSize: 0.92,
      builder: (_, __) => PaywallScreen(
        onDismiss: () => Navigator.pop(ctx),
      ),
    ),
  );
}
