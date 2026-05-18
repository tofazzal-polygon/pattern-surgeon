// Strategy pattern applied: interface + per-variant classes + map dispatch.
abstract interface class PricingStrategy {
  double price(double base);
}

class Regular implements PricingStrategy {
  @override double price(double base) => base;
}

class Vip implements PricingStrategy {
  @override double price(double base) => base * 0.8;
}

class Staff implements PricingStrategy {
  @override double price(double base) => base * 0.5;
}

final _strategies = <String, PricingStrategy>{
  'regular': Regular(), 'vip': Vip(), 'staff': Staff(),
};

double price(String kind, double base) => _strategies[kind]!.price(base);

double discountedTotal(String kind, double base, int qty) =>
    price(kind, base) * qty;
