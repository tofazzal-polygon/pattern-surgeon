// Failing test for not-yet-built behavior: `notify` does not exist yet.
let notify;
try { ({ notify } = require("./impl.js")); }
catch { console.error("impl.js missing — expected red"); process.exit(1); }

const out = [];
const orig = console.log;
console.log = (...a) => out.push(a.join(" "));
notify("email", "hi");
console.log = orig;
if (out.join("") !== "email hi") { console.error("wrong output"); process.exit(1); }
console.log("ok");
