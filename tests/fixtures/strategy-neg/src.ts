// WHEN NOT TO APPLY: a single 2-branch boolean toggle at exactly one site.
// Only two stable cases, one call location -> Strategy would be over-engineering.
export function shippingCost(base: number, isExpress: boolean): number {
  return isExpress ? base + 20 : base;
}
