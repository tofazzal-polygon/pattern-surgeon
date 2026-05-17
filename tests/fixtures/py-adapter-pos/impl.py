# SMELL: domain code speaks dollars but calls a third-party API that wants
# integer cents + positional args. The mismatch is handled inline at the call
# site. Candidate for an Adapter wrapping the vendor SDK.


# --- pretend third-party vendor SDK (do not edit "vendor" surface) ---
def vendor_charge(cents: int, curr: str) -> dict:
    if not isinstance(cents, int):
        raise ValueError("cents must be integer")
    return {"ok": True, "charged": cents, "currency": curr}


def charge(dollars: float, currency: str) -> dict:
    cents = round(dollars * 100)
    res = vendor_charge(cents, currency.upper())
    return {"cents_charged": res["charged"], "currency": res["currency"]}
