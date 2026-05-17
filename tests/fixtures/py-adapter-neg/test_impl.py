from impl import notify


def test_notify_passthrough():
    r = notify({"to": "a@b.com", "body": "hi"})
    assert r["delivered"] is True
    assert r["to"] == "a@b.com"
    assert r["body"] == "hi"
