from impl import UserRepo, greet


def test_greet_via_repo():
    repo = UserRepo()
    assert greet(repo, 1) == "Hello Ada"
    assert greet(repo, 2) == "unknown"
