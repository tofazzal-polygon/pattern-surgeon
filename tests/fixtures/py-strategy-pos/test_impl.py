from impl import price


def test_price_branches():
    assert price("regular", 100) == 100
    assert price("vip", 100) == 80
    assert price("staff", 100) == 50
