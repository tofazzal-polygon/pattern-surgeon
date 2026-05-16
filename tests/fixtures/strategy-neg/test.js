const { shippingCost } = require("./impl.js");

if (shippingCost(100, false) !== 100) {
  console.error("FAIL shippingCost(100,false)");
  process.exit(1);
}
if (shippingCost(100, true) !== 120) {
  console.error("FAIL shippingCost(100,true)");
  process.exit(1);
}
console.log("ok strategy-neg");
process.exit(0);
