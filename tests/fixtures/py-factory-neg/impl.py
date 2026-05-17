# WHEN NOT TO APPLY: exactly one concrete type, constructed once, no variation.
# A Factory would add indirection with zero payoff.


class Clock:
    kind = "system"

    def now(self) -> int:
        return 42


clock = Clock()


def current_tick() -> int:
    return clock.now()
