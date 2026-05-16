// SMELL: domain code speaks dollars/objects but calls a third-party API that
// wants integer cents + positional args. The mismatch is handled inline at the
// call site. Candidate for an Adapter wrapping the vendor SDK.

// --- pretend third-party vendor SDK (do not edit "vendor" surface) ---
const vendor = {
  vendorCharge(cents, curr) {
    if (!Number.isInteger(cents)) throw new Error("cents must be integer");
    return { ok: true, charged: cents, currency: curr };
  },
};

// domain-level call: caller passes a domain object, conversion happens inline
function charge(req) {
  const cents = Math.round(req.amountDollars * 100);
  const res = vendor.vendorCharge(cents, req.currency.toUpperCase());
  return { centsCharged: res.charged, currency: res.currency };
}

module.exports = { charge };
