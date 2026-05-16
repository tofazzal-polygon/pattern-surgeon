// SMELL: the class constructs its own collaborator internally, so it cannot be
// tested or reconfigured without reaching into globals. Candidate for DI.
class IdGen {
  next() { return "id-fixed"; }
}

class OrderService {
  constructor() {
    // hard-wired collaborator
    this.ids = new IdGen();
    this.created = [];
  }
  create(name) {
    const id = this.ids.next();
    this.created.push({ id, name });
    return id;
  }
}

module.exports = { OrderService };
