// WHEN NOT TO APPLY: the library's interface already matches the domain shape
// and is called from a single place. Wrapping it in an Adapter adds a
// pass-through layer with no translation value.
export interface Message {
  to: string;
  body: string;
}

const mailer = {
  send(message: Message): { delivered: boolean; to: string; body: string } {
    return { delivered: true, to: message.to, body: message.body };
  },
};

export function notify(message: Message): { delivered: boolean; to: string; body: string } {
  return mailer.send(message);
}
