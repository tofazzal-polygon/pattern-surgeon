const { makeSystem } = require("./impl.js");

const sys = makeSystem();
sys.placeOrder(7);

if (sys.auditLog.length !== 1 || sys.auditLog[0] !== "order:7") {
  console.error("FAIL auditLog => " + JSON.stringify(sys.auditLog));
  process.exit(1);
}
if (sys.emails.length !== 1 || sys.emails[0] !== "receipt:7") {
  console.error("FAIL emails => " + JSON.stringify(sys.emails));
  process.exit(1);
}
console.log("ok observer-pos");
process.exit(0);
