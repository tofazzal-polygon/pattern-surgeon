// SMELL: domain code speaks dollars/objects but calls a third-party API that
// wants integer cents + positional args. The mismatch is handled inline at the
// call site. Candidate for an Adapter wrapping the vendor SDK.

// --- pretend third-party vendor SDK (do not edit "vendor" surface) ---
const vendor = {
  vendorCharge(cents: number, curr: string): { ok: boolean; charged: number; currency: string } {
    if (!Number.isInteger(cents)) throw new Error("cents must be integer");
    return { ok: true, charged: cents, currency: curr };
  },
};

export interface ChargeRequest {
  amountDollars: number;
  currency: string;
}

export interface ChargeResult {
  centsCharged: number;
  currency: string;
}

export function charge(req: ChargeRequest): ChargeResult {
  const cents = Math.round(req.amountDollars * 100);
  const res = vendor.vendorCharge(cents, req.currency.toUpperCase());
  return { centsCharged: res.charged, currency: res.currency };
}
