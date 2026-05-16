const { makeSystem } = require("./impl.js");

const sys = makeSystem();
sys.placeOrder(3);

if (sys.auditLog.length !== 1 || sys.auditLog[0] !== "order:3") {
  console.error("FAIL auditLog => " + JSON.stringify(sys.auditLog));
  process.exit(1);
}
console.log("ok observer-neg");
process.exit(0);
