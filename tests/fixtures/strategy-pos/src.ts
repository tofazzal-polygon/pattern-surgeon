// SMELL: pricing logic branches on a `kind` string. Conceptually duplicated
// across the codebase wherever a price is computed. Candidate for Strategy.
export type Kind = "regular" | "vip" | "staff";

export function price(kind: Kind, base: number): number {
  if (kind === "regular") {
    return base;
  } else if (kind === "vip") {
    return base * 0.8;
  } else if (kind === "staff") {
    return base * 0.5;
  }
  throw new Error("unknown kind: " + kind);
}
