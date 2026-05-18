import 'package:test/test.dart';
import 'package:dart_strategy_neg/pricing.dart';

void main() {
  test('regular price unchanged', () => expect(price('regular', 100), 100.0));
  test('vip gets 20% off', () => expect(price('vip', 100), 80.0));
  test('staff gets 50% off', () => expect(price('staff', 100), 50.0));
  test('discounted total for vip', () => expect(discountedTotal('vip', 100, 2), 160.0));
}
