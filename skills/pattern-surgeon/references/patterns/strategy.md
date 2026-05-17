# Strategy

## Smell signature
The same `switch`/`if-else` over a type/enum/string appears in ≥2 sites and
branches differ only by algorithm. Example:
```ts
function price(kind: string, base: number) {
  if (kind === "regular") return base;
  if (kind === "vip") return base * 0.8;
  if (kind === "staff") return base * 0.5;
}
```

## When NOT to apply
- Only one call site and unlikely to grow.
- Branches share heavy mutable state.
- Fewer than 3 cases.

## Transform recipe
1. Define `interface PricingStrategy { price(base: number): number }`.
2. One class per branch implementing it.
3. Replace conditionals with a `Record<string, PricingStrategy>` lookup.
4. Inject/select the strategy at the call boundary.

```python
from typing import Protocol


class PricingStrategy(Protocol):
    def price(self, base: float) -> float: ...


class Regular:
    def price(self, base: float) -> float:
        return base


class Vip:
    def price(self, base: float) -> float:
        return base * 0.8


class Staff:
    def price(self, base: float) -> float:
        return base * 0.5


STRATEGIES: dict[str, PricingStrategy] = {
    "regular": Regular(),
    "vip": Vip(),
    "staff": Staff(),
}


def price(kind: str, base: float) -> float:
    # default/unknown branch preserved: KeyError signals an unknown kind
    return STRATEGIES[kind].price(base)
```
```java
import java.util.Map;

interface PricingStrategy { double price(double base); }

final class Regular implements PricingStrategy {
    public double price(double b) { return b; }
}

final class Vip implements PricingStrategy {
    public double price(double b) { return b * 0.8; }
}

final class Staff implements PricingStrategy {
    public double price(double b) { return b * 0.5; }
}

final class Pricing {
    static final Map<String, PricingStrategy> S = Map.of(
        "regular", new Regular(),
        "vip", new Vip(),
        "staff", new Staff());

    static double price(String kind, double base) {
        // default/unknown branch preserved: missing key -> NullPointerException
        return S.get(kind).price(base);
    }
}
```
```csharp
// TODO(phase-3): csharp example
```
```php
// TODO(phase-4): php example
```

## Framework idiom
- Spring Boot: no framework-specific idiom; a `@Component` may hold the strategy map.
- .NET Core: no framework-specific idiom; register strategies via keyed DI if desired.
- Laravel: no framework-specific idiom; resolve strategy from the service container if desired.

## Before / After
Before: the conditional above duplicated in checkout + invoice.
After:
```ts
interface PricingStrategy { price(base: number): number }

const strategies: Record<string, PricingStrategy> = {
  regular: { price: (b) => b },
  vip: { price: (b) => b * 0.8 },
  staff: { price: (b) => b * 0.5 },
};

// both sites:
const total = strategies[kind].price(base);
```

## Verification focus
Same numeric outputs for every previously handled `kind`; default/unknown
branch preserved.

## Pitfalls
Do not create a strategy per value when a data table suffices. Keep the
selection map in one place.
