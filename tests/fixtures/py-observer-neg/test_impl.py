from impl import make_system


def test_single_listener():
    sys = make_system()
    sys.place_order(3)
    assert sys.audit_log == ["order:3"]
