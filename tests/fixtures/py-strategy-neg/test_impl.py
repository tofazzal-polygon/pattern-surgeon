from impl import shipping_cost


def test_both_branches():
    assert shipping_cost(100, False) == 100
    assert shipping_cost(100, True) == 120
