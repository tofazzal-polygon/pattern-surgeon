# WHEN NOT TO APPLY: a pure function with no collaborators, side effects, or
# hidden state. There is nothing to inject; DI would only add ceremony.


def total(items) -> float:
    return sum(x["qty"] * x["price"] for x in items)
