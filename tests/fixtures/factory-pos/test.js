const { createConn } = require("./impl.js");

const cases = [
  ["mysql", "mysql", "mysql-pong"],
  ["pg", "pg", "pg-pong"],
  ["sqlite", "sqlite", "sqlite-pong"],
];

for (const [driver, kind, pong] of cases) {
  const c = createConn(driver);
  if (c.kind !== kind || c.ping() !== pong) {
    console.error(`FAIL createConn(${driver}) => kind=${c.kind} ping=${c.ping()}`);
    process.exit(1);
  }
}
console.log("ok factory-pos");
process.exit(0);
