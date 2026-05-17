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
// TODO(phase-3): csharp example
```
```php
// TODO(phase-4): php example
```

## Framework idiom
- Spring Boot: use constructor injection with `@Component`/`@Service`; let the container wire — do not `new` collaborators.
- .NET Core: register in `IServiceCollection` (`AddScoped`/`AddSingleton`) and constructor-inject; do not `new`.
- Laravel: type-hint collaborators in the constructor; the service container auto-resolves; bind interfaces in a ServiceProvider.

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
