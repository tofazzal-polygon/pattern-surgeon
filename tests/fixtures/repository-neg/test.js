const { makeUserRepo, greet } = require("./impl.js");

const repo = makeUserRepo();
if (greet(repo, 1) !== "Hello Ada") {
  console.error("FAIL greet(repo,1)");
  process.exit(1);
}
if (greet(repo, 2) !== "unknown") {
  console.error("FAIL greet(repo,2)");
  process.exit(1);
}
console.log("ok repository-neg");
process.exit(0);
