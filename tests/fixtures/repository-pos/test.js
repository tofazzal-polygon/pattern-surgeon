const { getActiveUserName } = require("./impl.js");

if (getActiveUserName(1) !== "ADA") {
  console.error("FAIL getActiveUserName(1)");
  process.exit(1);
}
if (getActiveUserName(2) !== null) {
  console.error("FAIL getActiveUserName(2) should be null (inactive)");
  process.exit(1);
}
if (getActiveUserName(99) !== null) {
  console.error("FAIL getActiveUserName(99) should be null (missing)");
  process.exit(1);
}
console.log("ok repository-pos");
process.exit(0);
