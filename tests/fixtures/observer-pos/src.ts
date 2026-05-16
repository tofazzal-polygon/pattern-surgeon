// SMELL: the producer hard-codes calls to multiple concrete consumers. Adding
// a new reaction means editing the producer. Candidate for Observer/pub-sub.
export interface OrderSystem {
  placeOrder(id: number): void;
  auditLog: string[];
  emails: string[];
}

export function makeSystem(): OrderSystem {
  const auditLog: string[] = [];
  const emails: string[] = [];

  function placeOrder(id: number): void {
    // producer directly invokes each consumer
    auditLog.push("order:" + id);
    emails.push("receipt:" + id);
  }

  return { placeOrder, auditLog, emails };
}
