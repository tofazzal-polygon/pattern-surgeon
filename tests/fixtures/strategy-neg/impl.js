// WHEN NOT TO APPLY: a single 2-branch boolean toggle at exactly one site.
// Only two stable cases, one call location -> Strategy would be over-engineering.
function shippingCost(base, isExpress) {
  return isExpress ? base + 20 : base;
}

module.exports = { shippingCost };
