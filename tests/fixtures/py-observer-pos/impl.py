# SMELL: the producer hard-codes calls to multiple concrete consumers. Adding
# a new reaction means editing the producer. Candidate for Observer/pub-sub.


class OrderSystem:
    def __init__(self):
        self.audit_log = []
        self.emails = []

    def place_order(self, order_id: int) -> None:
        # producer directly invokes each consumer
        self.audit_log.append("order:" + str(order_id))
        self.emails.append("receipt:" + str(order_id))


def make_system() -> OrderSystem:
    return OrderSystem()
