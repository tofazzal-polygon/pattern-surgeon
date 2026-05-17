from impl import current_tick


def test_current_tick():
    assert current_tick() == 42
