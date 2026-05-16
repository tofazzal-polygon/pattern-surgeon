// SMELL: construction switches on a `driver` string. The same `new XConn()`
// selection is conceptually repeated at multiple call spots. Candidate for Factory.
export type Driver = "mysql" | "pg" | "sqlite";

export interface Conn {
  kind: Driver;
  ping(): string;
}

class MySQLConn implements Conn {
  kind: Driver = "mysql";
  ping(): string { return "mysql-pong"; }
}
class PgConn implements Conn {
  kind: Driver = "pg";
  ping(): string { return "pg-pong"; }
}
class SqliteConn implements Conn {
  kind: Driver = "sqlite";
  ping(): string { return "sqlite-pong"; }
}

export function createConn(driver: Driver): Conn {
  if (driver === "mysql") return new MySQLConn();
  if (driver === "pg") return new PgConn();
  if (driver === "sqlite") return new SqliteConn();
  throw new Error("unknown driver: " + driver);
}
