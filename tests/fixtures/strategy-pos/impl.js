// SMELL: pricing logic branches on a `kind` string. Conceptually duplicated
// across the codebase wherever a price is computed. Candidate for Strategy.
function price(kind, base) {
  if (kind === "regular") {
    return base;
  } else if (kind === "vip") {
    return base * 0.8;
  } else if (kind === "staff") {
    return base * 0.5;
  }
  throw new Error("unknown kind: " + kind);
}

module.exports = { price };
