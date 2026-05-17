# SMELL: pricing logic branches on a `kind` string. Conceptually duplicated
# across the codebase wherever a price is computed. Candidate for Strategy.


def price(kind: str, base: float) -> float:
    if kind == "regular":
        return base
    elif kind == "vip":
        return base * 0.8
    elif kind == "staff":
        return base * 0.5
    raise ValueError("unknown kind: " + kind)
