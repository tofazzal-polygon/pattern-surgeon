// WHEN NOT TO APPLY: the library's interface already matches the domain shape
// and is called from a single place. Wrapping it in an Adapter adds a
// pass-through layer with no translation value.
const mailer = {
  send(message) {
    return { delivered: true, to: message.to, body: message.body };
  },
};

function notify(message) {
  return mailer.send(message);
}

module.exports = { notify };
