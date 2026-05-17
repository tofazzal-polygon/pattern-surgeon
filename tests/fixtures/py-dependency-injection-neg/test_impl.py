from impl import total


def test_total_pure():
    assert total([{"qty": 2, "price": 5}, {"qty": 3, "price": 10}]) == 40
    assert total([]) == 0
