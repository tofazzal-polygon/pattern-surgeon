# SMELL: the class constructs its own collaborator internally, so it cannot be
# tested or reconfigured without reaching into globals. Candidate for DI.


class IdGen:
    def next(self) -> str:
        return "id-fixed"


class OrderService:
    def __init__(self):
        # hard-wired collaborator
        self._ids = IdGen()
        self.created = []

    def create(self, name: str) -> str:
        new_id = self._ids.next()
        self.created.append({"id": new_id, "name": name})
        return new_id
