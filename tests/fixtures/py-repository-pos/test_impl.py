from impl import get_active_user_name


def test_get_active_user_name():
    assert get_active_user_name(1) == "ADA"
    assert get_active_user_name(2) is None  # inactive
    assert get_active_user_name(99) is None  # missing
