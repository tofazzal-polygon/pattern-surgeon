const { currentTick } = require("./impl.js");

if (currentTick() !== 42) {
  console.error("FAIL currentTick");
  process.exit(1);
}
console.log("ok factory-neg");
process.exit(0);
