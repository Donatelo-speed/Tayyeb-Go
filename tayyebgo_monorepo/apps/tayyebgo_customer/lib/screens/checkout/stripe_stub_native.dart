// Native/mobile Stripe implementation — imports flutter_stripe.
// This file is used on mobile via conditional import.

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeWrapper {
  Future<void> initPaymentSheet({
    required String clientSecret,
    required String merchantDisplayName,
  }) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: merchantDisplayName,
        style: ThemeMode.system,
      ),
    );
  }

  Future<void> presentPaymentSheet() async {
    await Stripe.instance.presentPaymentSheet();
  }
}

StripeWrapper createStripeWrapper() => StripeWrapper();
