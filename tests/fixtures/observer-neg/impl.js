// WHEN NOT TO APPLY: exactly one consumer reacts to the event, with no
// expectation of more. A direct call is clearer than a pub-sub indirection.
function makeSystem() {
  const auditLog = [];

  function placeOrder(id) {
    auditLog.push("order:" + id);
  }

  return { placeOrder, auditLog };
}

module.exports = { makeSystem };
