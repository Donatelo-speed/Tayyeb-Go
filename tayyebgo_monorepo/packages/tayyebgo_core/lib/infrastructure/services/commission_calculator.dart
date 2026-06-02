import '../../domain/value_objects/money.dart';

class CommissionCalculator {
  Money calculate(Money grossAmount, double commissionPercent) {
    final commissionCents = (grossAmount.amountInCents * commissionPercent / 100).round();
    return Money(commissionCents);
  }

  Money netAfterCommission(Money grossAmount, double commissionPercent) {
    return grossAmount - calculate(grossAmount, commissionPercent);
  }
}
