const { OrderService } = require("./impl.js");

const svc = new OrderService();
const id = svc.create("widget");

if (id !== "id-fixed") {
  console.error("FAIL create returned " + id);
  process.exit(1);
}
if (svc.created.length !== 1 || svc.created[0].name !== "widget" || svc.created[0].id !== "id-fixed") {
  console.error("FAIL created => " + JSON.stringify(svc.created));
  process.exit(1);
}
console.log("ok dependency-injection-pos");
process.exit(0);
