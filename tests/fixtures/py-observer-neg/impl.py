# WHEN NOT TO APPLY: exactly one consumer reacts to the event, with no
# expectation of more. A direct call is clearer than a pub-sub indirection.


class OrderSystem:
    def __init__(self):
        self.audit_log = []

    def place_order(self, order_id: int) -> None:
        self.audit_log.append("order:" + str(order_id))


def make_system() -> OrderSystem:
    return OrderSystem()
