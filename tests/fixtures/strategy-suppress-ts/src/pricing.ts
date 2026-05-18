// SUPPRESS CASE: only 2 branches — "When NOT to apply: fewer than 3 cases".
// The Strategy detection rule fires (same switch at 2 sites, differs by algorithm)
// but the "< 3 cases" suppression condition holds — do NOT recommend Strategy.
export function price(kind: "regular" | "vip", base: number): number {
  if (kind === "regular") return base;
  if (kind === "vip") return base * 0.8;
  throw new Error(`unknown kind: ${kind}`);
}

export function label(kind: "regular" | "vip"): string {
  if (kind === "regular") return "Standard";
  if (kind === "vip") return "VIP";
  throw new Error(`unknown kind: ${kind}`);
}
