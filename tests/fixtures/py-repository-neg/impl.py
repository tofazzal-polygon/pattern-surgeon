# WHEN NOT TO APPLY: data access is already isolated behind a repository
# abstraction; the service only depends on that abstraction. Nothing to extract.


class UserRepo:
    def __init__(self):
        self._users = [{"id": 1, "name": "Ada"}]

    def find_by_id(self, user_id: int):
        for u in self._users:
            if u["id"] == user_id:
                return u
        return None


def greet(repo: UserRepo, user_id: int) -> str:
    u = repo.find_by_id(user_id)
    return "Hello " + u["name"] if u else "unknown"
