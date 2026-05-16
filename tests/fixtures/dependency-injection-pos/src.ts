// SMELL: the class constructs its own collaborator internally, so it cannot be
// tested or reconfigured without reaching into globals. Candidate for DI.
class IdGen {
  next(): string { return "id-fixed"; }
}

export class OrderService {
  private ids: IdGen;
  created: { id: string; name: string }[];

  constructor() {
    // hard-wired collaborator
    this.ids = new IdGen();
    this.created = [];
  }

  create(name: string): string {
    const id = this.ids.next();
    this.created.push({ id, name });
    return id;
  }
}
