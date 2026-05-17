from impl import make_system


def test_both_consumers_saw_event():
    sys = make_system()
    sys.place_order(7)
    assert sys.audit_log == ["order:7"]
    assert sys.emails == ["receipt:7"]
