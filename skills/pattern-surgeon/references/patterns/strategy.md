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
using System.Collections.Generic;

interface IPricingStrategy { double Price(double b); }

sealed class Regular : IPricingStrategy { public double Price(double b) => b; }
sealed class Vip : IPricingStrategy { public double Price(double b) => b * 0.8; }
sealed class Staff : IPricingStrategy { public double Price(double b) => b * 0.5; }

static class Pricing {
    static readonly Dictionary<string, IPricingStrategy> S = new() {
        ["regular"] = new Regular(), ["vip"] = new Vip(), ["staff"] = new Staff()
    };

    // default/unknown branch preserved: missing key -> KeyNotFoundException
    public static double Price(string kind, double b) => S[kind].Price(b);
}
```
```php
declare(strict_types=1);

interface PricingStrategy { public function price(float $base): float; }

final class Regular implements PricingStrategy {
    public function price(float $b): float { return $b; }
}

final class Vip implements PricingStrategy {
    public function price(float $b): float { return $b * 0.8; }
}

final class Staff implements PricingStrategy {
    public function price(float $b): float { return $b * 0.5; }
}

final class Pricing {
    /** @var array<string,PricingStrategy> */
    private array $s;

    public function __construct() {
        $this->s = [
            'regular' => new Regular(),
            'vip' => new Vip(),
            'staff' => new Staff(),
        ];
    }

    public function price(string $kind, float $base): float {
        // default/unknown branch preserved: unknown $kind raises a warning/Error
        return $this->s[$kind]->price($base);
    }
}
```

```kotlin
interface PricingStrategy { fun price(base: Double): Double }

object Regular : PricingStrategy { override fun price(base: Double) = base }
object Vip     : PricingStrategy { override fun price(base: Double) = base * 0.8 }
object Staff   : PricingStrategy { override fun price(base: Double) = base * 0.5 }

private val strategies = mapOf<String, PricingStrategy>(
    "regular" to Regular, "vip" to Vip, "staff" to Staff,
)

fun price(kind: String, base: Double): Double =
    strategies[kind]?.price(base) ?: error("Unknown kind: $kind")
```
```dart
abstract interface class PricingStrategy {
  double price(double base);
}

class Regular implements PricingStrategy {
  @override double price(double base) => base;
}
class Vip implements PricingStrategy {
  @override double price(double base) => base * 0.8;
}
class Staff implements PricingStrategy {
  @override double price(double base) => base * 0.5;
}

final _strategies = <String, PricingStrategy>{
  'regular': Regular(), 'vip': Vip(), 'staff': Staff(),
};

double price(String kind, double base) => _strategies[kind]!.price(base);
```
```swift
protocol PricingStrategy { func price(base: Double) -> Double }

struct Regular: PricingStrategy { func price(base: Double) -> Double { base } }
struct Vip:     PricingStrategy { func price(base: Double) -> Double { base * 0.8 } }
struct Staff:   PricingStrategy { func price(base: Double) -> Double { base * 0.5 } }

private let strategies: [String: any PricingStrategy] = [
    "regular": Regular(), "vip": Vip(), "staff": Staff(),
]

func price(kind: String, base: Double) -> Double {
    guard let s = strategies[kind] else { fatalError("Unknown kind: \(kind)") }
    return s.price(base: base)
}
```

## Framework idiom
- Spring Boot: no framework-specific idiom; a `@Component` may hold the strategy map.
- .NET Core: no framework-specific idiom; register strategies via keyed DI if desired.
- Laravel: no framework-specific idiom; resolve strategy from the service container if desired.
- Android/Kotlin: no framework-specific idiom; hold the strategy map in a ViewModel or use-case class.
- Flutter/Dart: no framework-specific idiom; inject strategies via constructor or a Riverpod provider.
- Swift/iOS: no framework-specific idiom; use a `[String: any PricingStrategy]` dictionary; compatible with SwiftUI ViewModels.

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
