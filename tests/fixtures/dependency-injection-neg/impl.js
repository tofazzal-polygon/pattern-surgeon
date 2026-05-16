// WHEN NOT TO APPLY: a pure function with no collaborators, side effects, or
// hidden state. There is nothing to inject; DI would only add ceremony.
function total(items) {
  return items.reduce((sum, x) => sum + x.qty * x.price, 0);
}

module.exports = { total };
