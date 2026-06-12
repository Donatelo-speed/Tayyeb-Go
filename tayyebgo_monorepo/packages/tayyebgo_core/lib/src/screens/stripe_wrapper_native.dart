// Native/mobile Stripe implementation for core package.

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class CoreStripeWrapper {
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

CoreStripeWrapper createCoreStripeWrapper() => CoreStripeWrapper();
