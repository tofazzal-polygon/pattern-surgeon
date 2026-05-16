const { charge } = require("./impl.js");

const r = charge({ amountDollars: 12.34, currency: "usd" });
if (r.centsCharged !== 1234) {
  console.error(`FAIL centsCharged => ${r.centsCharged}, expected 1234`);
  process.exit(1);
}
if (r.currency !== "USD") {
  console.error(`FAIL currency => ${r.currency}, expected USD`);
  process.exit(1);
}
console.log("ok adapter-pos");
process.exit(0);
