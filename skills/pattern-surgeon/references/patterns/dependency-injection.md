# Dependency Injection

## Smell signature
A class does `new Collaborator()` internally, reads hard-coded
singletons/globals, or hidden dependencies make it untestable. Example:
```ts
class OrderService {
  private db = new Db(process.env.DB_URL!);   // hidden, untestable
  private clock = Date;                        // global
  place(o: Order) { /* uses this.db, this.clock */ }
}
```

## When NOT to apply
- Pure functions and value objects (no collaborators).
- Leaf utilities with no I/O or external dependencies.
- Plain config constants.

## Transform recipe
1. Lift each collaborator to a constructor parameter, typed by an interface.
2. Construct and wire the real implementations at the composition root.
3. Pass test doubles in tests via the same constructor.

```python
from datetime import datetime
from typing import Protocol


# BEFORE: hidden, untestable collaborators
# class OrderService:
#     def __init__(self) -> None:
#         self.db = Db(os.environ["DB_URL"])   # hidden
#         self.clock = datetime               # global


# AFTER: collaborators lifted to constructor params, typed by Protocols
class DbPort(Protocol):
    def insert(self, order: dict) -> None: ...


class Clock(Protocol):
    def now(self) -> datetime: ...


class OrderService:
    def __init__(self, db: DbPort, clock: Clock) -> None:
        self._db = db
        self._clock = clock

    def place(self, order: dict) -> None:
        self._db.insert({**order, "at": self._clock.now()})


# composition root: wire the real implementations
# svc = OrderService(Db(os.environ["DB_URL"]), SystemClock())

# test: a test double can be injected via the same constructor
# svc = OrderService(FakeDb(), FixedClock(datetime(2026, 1, 1)))
```
```java
import java.time.Instant;
import java.util.Map;

// BEFORE: hidden, untestable collaborators
// final class OrderService {
//     private final Db db = new Db(System.getenv("DB_URL")); // hidden
//     private final Clock clock = Clock.systemUTC();          // global
// }

// AFTER: collaborators lifted to constructor params, typed by interfaces
interface DbPort {
    void insert(Map<String, Object> order);
}

interface ClockPort {
    Instant now();
}

final class OrderService {
    private final DbPort db;
    private final ClockPort clock;

    OrderService(DbPort db, ClockPort clock) {
        this.db = db;
        this.clock = clock;
    }

    void place(Map<String, Object> order) {
        order.put("at", clock.now());
        db.insert(order);
    }
}

// composition root: wire the real implementations
// var svc = new OrderService(new Db(System.getenv("DB_URL")), Instant::now);

// test: a test double can be injected via the same constructor
// var svc = new OrderService(new FakeDb(), () -> Instant.parse("2026-01-01T00:00:00Z"));
```
```csharp
using System;
using System.Collections.Generic;

// BEFORE: hidden, untestable collaborators
// sealed class OrderService {
//     private readonly Db _db = new Db(Environment.GetEnvironmentVariable("DB_URL")); // hidden
//     private readonly Func<DateTime> _clock = () => DateTime.UtcNow;                  // global
// }

// AFTER: collaborators lifted to constructor params, typed by interfaces
interface IDb {
    void Insert(Dictionary<string, object> order);
}

interface IClock {
    DateTime Now();
}

sealed class OrderService {
    private readonly IDb _db;
    private readonly IClock _clock;

    public OrderService(IDb db, IClock clock) {
        _db = db;
        _clock = clock;
    }

    public void Place(Dictionary<string, object> order) {
        order["at"] = _clock.Now();
        _db.Insert(order);
    }
}

// composition root: register against interfaces, constructor-inject
// services.AddSingleton<IDb, Db>();
// services.AddSingleton<IClock, SystemClock>();
// services.AddScoped<OrderService>();

// test: a test double can be injected via the same constructor
// var svc = new OrderService(new FakeDb(), new FixedClock(new DateTime(2026, 1, 1)));
```
```php
declare(strict_types=1);

// BEFORE: hidden, untestable collaborators
// final class OrderService {
//     private Db $db;
//     public function __construct() {
//         $this->db = new Db(getenv('DB_URL'));   // hidden, untestable
//     }
// }

// AFTER: collaborators lifted to constructor params, typed by interfaces
interface Db {
    public function insert(array $order): void;
}

interface Clock {
    public function now(): \DateTimeImmutable;
}

final class OrderService {
    public function __construct(private Db $db, private Clock $clock) {}

    public function place(array $order): void {
        $order['at'] = $this->clock->now();
        $this->db->insert($order);
    }
}

// composition root: wire the real implementations
// $svc = new OrderService(new RealDb(getenv('DB_URL')), new SystemClock());

// Laravel: type-hint Db/Clock in the constructor and the service container
// auto-resolves them (bind the interfaces in a ServiceProvider).
// test: a test double can be injected via the same constructor
// $svc = new OrderService(new FakeDb(), new FixedClock(new \DateTimeImmutable('2026-01-01')));
```

```kotlin
import java.time.Instant

// BEFORE: hidden, untestable collaborators
// class OrderService {
//     private val db = Db(System.getenv("DB_URL"))   // hidden
// }

// AFTER: collaborators lifted to constructor params, typed by interfaces
interface DbPort { fun insert(order: Map<String, Any>) }
interface ClockPort { fun now(): Instant }

class OrderService(private val db: DbPort, private val clock: ClockPort) {
    fun place(order: Map<String, Any>) {
        db.insert(order + ("at" to clock.now()))
    }
}

// composition root: wire the real implementations
// val svc = OrderService(Db(System.getenv("DB_URL")), SystemClock())

// test: a test double can be injected via the same constructor
// val svc = OrderService(FakeDb(), FixedClock(Instant.parse("2026-01-01T00:00:00Z")))
```
```dart
// BEFORE: hidden, untestable collaborators
// class OrderService {
//   final _db = Db(Platform.environment['DB_URL']!);   // hidden
// }

// AFTER: collaborators lifted to constructor params, typed by interfaces
abstract interface class DbPort { void insert(Map<String, Object> order); }
abstract interface class ClockPort { DateTime now(); }

class OrderService {
  final DbPort _db;
  final ClockPort _clock;
  // collaborators lifted to constructor params
  OrderService(this._db, this._clock);

  void place(Map<String, Object> order) {
    _db.insert({...order, 'at': _clock.now()});
  }
}

// composition root: wire the real implementations
// final svc = OrderService(Db(Platform.environment['DB_URL']!), SystemClock());

// test: a test double can be injected via the same constructor
// final svc = OrderService(FakeDb(), FixedClock(DateTime(2026, 1, 1)));
```
```swift
import Foundation

// BEFORE: hidden, untestable collaborators
// class OrderService {
//     private let db = Db(ProcessInfo.processInfo.environment["DB_URL"]!)  // hidden
//     private let clock: () -> Date = Date.init                             // global
// }

// AFTER: collaborators lifted to init params, typed by protocols
protocol DbPort { func insert(_ order: [String: Any]) }
protocol ClockPort { func now() -> Date }

class OrderService {
    private let db: any DbPort
    private let clock: any ClockPort
    // collaborators lifted to init params
    init(db: any DbPort, clock: any ClockPort) { self.db = db; self.clock = clock }

    func place(_ order: [String: Any]) {
        var o = order; o["at"] = clock.now()
        db.insert(o)
    }
}

// composition root: wire the real implementations
// let svc = OrderService(db: RealDb(url: env["DB_URL"]!), clock: SystemClock())

// test: a test double can be injected via the same init
// let svc = OrderService(db: FakeDb(), clock: FixedClock(date: Date(timeIntervalSince1970: 0)))
```

## Framework idiom
- Spring Boot: use constructor injection with `@Component`/`@Service`; let the container wire — do not `new` collaborators.
- .NET Core: register in `IServiceCollection` (`AddScoped`/`AddSingleton`) and constructor-inject; do not `new`.
- Laravel: type-hint collaborators in the constructor; the service container auto-resolves; bind interfaces in a ServiceProvider.
- Android/Kotlin: use Hilt (`@Inject constructor`, `@HiltViewModel`); let the container wire — do not `new` collaborators.
- Flutter/Dart: use `get_it` or Riverpod `Provider`s to supply collaborators; avoid hidden `new` inside classes.
- Swift/iOS: use constructor injection; for SwiftUI pass dependencies via `@Environment`/`@EnvironmentObject`; for larger apps use Resolver or Swinject.

## Before / After
Before: `class OrderService { db = new Db() }`.
After:
```ts
interface DbPort { insert(o: Order): Promise<void> }
interface Clock { now(): Date }

class OrderService {
  constructor(private db: DbPort, private clock: Clock) {}
  place(o: Order) { return this.db.insert({ ...o, at: this.clock.now() }); }
}

// composition root:
const svc = new OrderService(new Db(process.env.DB_URL!), { now: () => new Date() });

// test:
const svc = new OrderService(fakeDb, { now: () => new Date("2026-01-01") });
```

## Verification focus
Identical runtime wiring in the production path; behavior unchanged; tests can
now inject fakes for previously-hidden deps.

## Pitfalls
Don't introduce a DI framework for a small object graph. Prefer constructor
injection over a service locator (which just hides the dependency again).
