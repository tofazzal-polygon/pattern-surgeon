// SMELL: construction switches on a `driver` string. The same `new XConn()`
// selection is conceptually repeated at multiple call spots. Candidate for Factory.
class MySQLConn {
  constructor() { this.kind = "mysql"; }
  ping() { return "mysql-pong"; }
}
class PgConn {
  constructor() { this.kind = "pg"; }
  ping() { return "pg-pong"; }
}
class SqliteConn {
  constructor() { this.kind = "sqlite"; }
  ping() { return "sqlite-pong"; }
}

function createConn(driver) {
  if (driver === "mysql") return new MySQLConn();
  if (driver === "pg") return new PgConn();
  if (driver === "sqlite") return new SqliteConn();
  throw new Error("unknown driver: " + driver);
}

module.exports = { createConn };
