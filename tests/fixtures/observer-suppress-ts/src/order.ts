// SUPPRESS CASE: single listener — "When NOT to apply: single listener".
// Order.complete() notifies exactly one consumer (emailService).
// Adding a Subject + subscribe/notify machinery for a single, stable
// listener adds indirection with no decoupling benefit.
interface EmailService { send(order: Order): void }

export class Order {
  status = "open";

  constructor(private readonly emailService: EmailService) {}

  complete(): void {
    this.status = "done";
    this.emailService.send(this); // one listener — direct call is correct here
  }
}
