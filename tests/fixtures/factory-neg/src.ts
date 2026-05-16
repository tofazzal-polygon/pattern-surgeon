// WHEN NOT TO APPLY: exactly one concrete type, constructed once, no variation.
// A Factory would add indirection with zero payoff.
class Clock {
  kind = "system";
  now(): number { return 42; }
}

const clock = new Clock();

export function currentTick(): number {
  return clock.now();
}
