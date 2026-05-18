// SMELL: same if/else over kind repeated in two functions — Strategy candidate.
double price(String kind, double base) {
  if (kind == 'regular') return base;
  if (kind == 'vip') return base * 0.8;
  if (kind == 'staff') return base * 0.5;
  throw ArgumentError('unknown kind: $kind');
}

double discountedTotal(String kind, double base, int qty) {
  double unit;
  if (kind == 'regular') {
    unit = base;
  } else if (kind == 'vip') {
    unit = base * 0.8;
  } else if (kind == 'staff') {
    unit = base * 0.5;
  } else {
    throw ArgumentError('unknown kind: $kind');
  }
  return unit * qty;
}
