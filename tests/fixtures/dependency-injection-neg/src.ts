// WHEN NOT TO APPLY: a pure function with no collaborators, side effects, or
// hidden state. There is nothing to inject; DI would only add ceremony.
export interface LineItem {
  qty: number;
  price: number;
}

export function total(items: LineItem[]): number {
  return items.reduce((sum, x) => sum + x.qty * x.price, 0);
}
