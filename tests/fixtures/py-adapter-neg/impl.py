# WHEN NOT TO APPLY: the library's interface already matches the domain shape
# and is called from a single place. Wrapping it in an Adapter adds a
# pass-through layer with no translation value.


def mailer_send(message: dict) -> dict:
    return {"delivered": True, "to": message["to"], "body": message["body"]}


def notify(message: dict) -> dict:
    return mailer_send(message)
