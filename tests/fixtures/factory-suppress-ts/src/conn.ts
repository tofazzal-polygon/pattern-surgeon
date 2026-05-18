// SUPPRESS CASE: single construction site — "When NOT to apply: trivial single construction".
// new PgConn() appears exactly once with no conditional branching.
// The Factory detection rule does NOT fire (< 3 places, no conditional).
export interface Conn { query(sql: string): Promise<string[]> }

export class PgConn implements Conn {
  constructor(private readonly url: string) {}
  async query(sql: string): Promise<string[]> { return []; }
}

// Single, unconditional construction — Factory adds zero value here.
export function buildConn(url: string): Conn {
  return new PgConn(url);
}
