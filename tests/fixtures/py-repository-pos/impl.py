# SMELL: the service function reaches straight into a data store, building a
# query inline. Persistence and business logic are entangled. Candidate for
# extracting a Repository.

DB = {
    "users": [
        {"id": 1, "name": "Ada", "active": True},
        {"id": 2, "name": "Lin", "active": False},
    ]
}


def get_active_user_name(user_id: int):
    # inline "query" interleaved with business logic
    rows = [u for u in DB["users"] if u["id"] == user_id and u["active"] is True]
    if not rows:
        return None
    return rows[0]["name"].upper()
