from impl import charge


def test_charge_translates_dollars_to_cents():
    r = charge(12.34, "usd")
    assert r["cents_charged"] == 1234
    assert r["currency"] == "USD"
