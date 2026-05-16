const { total } = require("./impl.js");

const got = total([
  { qty: 2, price: 5 },
  { qty: 3, price: 10 },
]);
if (got !== 40) {
  console.error("FAIL total => " + got + ", expected 40");
  process.exit(1);
}
if (total([]) !== 0) {
  console.error("FAIL total([]) should be 0");
  process.exit(1);
}
console.log("ok dependency-injection-neg");
process.exit(0);
