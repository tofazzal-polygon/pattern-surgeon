// SMELL: the producer hard-codes calls to multiple concrete consumers. Adding
// a new reaction means editing the producer. Candidate for Observer/pub-sub.
function makeSystem() {
  const auditLog = [];
  const emails = [];

  function placeOrder(id) {
    // producer directly invokes each consumer
    auditLog.push("order:" + id);
    emails.push("receipt:" + id);
  }

  return { placeOrder, auditLog, emails };
}

module.exports = { makeSystem };
