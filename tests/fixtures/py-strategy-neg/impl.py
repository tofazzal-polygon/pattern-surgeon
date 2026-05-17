# WHEN NOT TO APPLY: a single 2-branch boolean toggle at exactly one site.
# Only two stable cases, one call location -> Strategy would be over-engineering.


def shipping_cost(base: float, is_express: bool) -> float:
    return base + 20 if is_express else base
