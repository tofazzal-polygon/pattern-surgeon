// WHEN NOT TO APPLY: exactly one consumer reacts to the event, with no
// expectation of more. A direct call is clearer than a pub-sub indirection.
export interface OrderSystem {
  placeOrder(id: number): void;
  auditLog: string[];
}

export function makeSystem(): OrderSystem {
  const auditLog: string[] = [];

  function placeOrder(id: number): void {
    auditLog.push("order:" + id);
  }

  return { placeOrder, auditLog };
}
