export interface Order { id: string; total: number }

export class OrderRepository {
  async byId(id: string): Promise<Order | null> {
    const r = await fetch(`/api/orders/${id}`);
    return r.ok ? (await r.json()) as Order : null;
  }
}
