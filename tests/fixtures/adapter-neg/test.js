const { notify } = require("./impl.js");

const r = notify({ to: "a@b.com", body: "hi" });
if (!r.delivered || r.to !== "a@b.com" || r.body !== "hi") {
  console.error("FAIL notify => " + JSON.stringify(r));
  process.exit(1);
}
console.log("ok adapter-neg");
process.exit(0);
