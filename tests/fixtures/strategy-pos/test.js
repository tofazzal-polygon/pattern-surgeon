const { price } = require("./impl.js");

const cases = [
  ["regular", 100, 100],
  ["vip", 100, 80],
  ["staff", 100, 50],
];

for (const [kind, base, expected] of cases) {
  const got = price(kind, base);
  if (got !== expected) {
    console.error(`FAIL price(${kind}, ${base}) => ${got}, expected ${expected}`);
    process.exit(1);
  }
}
console.log("ok strategy-pos");
process.exit(0);
