// WHEN NOT TO APPLY: exactly one concrete type, constructed once, no variation.
// A Factory would add indirection with zero payoff.
class Clock {
  constructor() { this.kind = "system"; }
  now() { return 42; }
}

const clock = new Clock();

function currentTick() {
  return clock.now();
}

module.exports = { currentTick };
