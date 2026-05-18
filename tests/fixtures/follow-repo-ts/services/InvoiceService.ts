// Non-conforming: raw fetch inside the service instead of a Repository,
// breaking the established repo/ convention.
export class InvoiceService {
  async invoiceTotal(orderId: string): Promise<number> {
    const r = await fetch(`/api/orders/${orderId}`);
    const o = await r.json();
    return o.total * 1.2;
  }
}
