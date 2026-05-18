# Factory

## Smell signature
`new X()` of one family is scattered across ≥3 places and construction needs a
conditional or config to pick the concrete type. Example:
```ts
// repeated in 3+ modules
const conn = cfg.driver === "pg"
  ? new PgConn(cfg.url)
  : new MySQLConn(cfg.url);
```

## When NOT to apply
- Trivial single construction (`new Foo()` with no branching).
- A DI container / composition root already owns construction.
- Only one concrete type exists and it is stable (YAGNI).

## Transform recipe
1. Define the product interface, e.g. `interface Conn { query(sql: string): Promise<Row[]> }`.
2. Extract a `createConn(cfg): Conn` factory function (or class).
3. Move the conditional construction into the factory only.
4. Callers depend on `createConn` + `Conn`, never on concretes.

```python
from typing import Protocol


class Conn(Protocol):
    kind: str

    def query(self, sql: str) -> list[dict]: ...


class PgConn:
    kind = "pg"

    def __init__(self, url: str) -> None:
        self.url = url

    def query(self, sql: str) -> list[dict]:
        return []


class MySQLConn:
    kind = "mysql"

    def __init__(self, url: str) -> None:
        self.url = url

    def query(self, sql: str) -> list[dict]:
        return []


def create_conn(cfg: dict) -> Conn:
    driver = cfg["driver"]
    if driver == "pg":
        return PgConn(cfg["url"])
    if driver == "mysql":
        return MySQLConn(cfg["url"])
    raise ValueError(f"unknown driver {driver}")


# callers:
# conn = create_conn(cfg)
```
```java
interface Conn {
    String kind();
}

final class PgConn implements Conn {
    private final String url;
    PgConn(String url) { this.url = url; }
    public String kind() { return "pg"; }
}

final class MySQLConn implements Conn {
    private final String url;
    MySQLConn(String url) { this.url = url; }
    public String kind() { return "mysql"; }
}

final class ConnFactory {
    static Conn create(String driver, String url) {
        return switch (driver) {
            case "pg" -> new PgConn(url);
            case "mysql" -> new MySQLConn(url);
            default -> throw new IllegalArgumentException("unknown driver " + driver);
        };
    }
}

// callers:
// Conn conn = ConnFactory.create(cfg.driver(), cfg.url());
```
```csharp
using System;

interface IConn { string Kind { get; } }

sealed class MySqlConn : IConn {
    private readonly string _url;
    public MySqlConn(string url) { _url = url; }
    public string Kind => "mysql";
}

sealed class PgConn : IConn {
    private readonly string _url;
    public PgConn(string url) { _url = url; }
    public string Kind => "pg";
}

static class ConnFactory {
    public static IConn Create(string driver, string url) => driver switch {
        "pg" => new PgConn(url),
        "mysql" => new MySqlConn(url),
        _ => throw new ArgumentException($"unknown driver {driver}"),
    };
}

// callers:
// IConn conn = ConnFactory.Create(cfg.Driver, cfg.Url);
```
```php
declare(strict_types=1);

interface Conn { public function kind(): string; }

final class PgConn implements Conn {
    public function __construct(private string $url) {}
    public function kind(): string { return 'pg'; }
}

final class MySQLConn implements Conn {
    public function __construct(private string $url) {}
    public function kind(): string { return 'mysql'; }
}

final class ConnFactory {
    public static function create(string $driver, string $url): Conn {
        return match ($driver) {
            'pg' => new PgConn($url),
            'mysql' => new MySQLConn($url),
            default => throw new \InvalidArgumentException("unknown driver $driver"),
        };
    }
}

// callers:
// $conn = ConnFactory::create($cfg['driver'], $cfg['url']);
```

```kotlin
interface Conn { val kind: String }

class PgConn(val url: String) : Conn { override val kind = "pg" }
class MySQLConn(val url: String) : Conn { override val kind = "mysql" }

object ConnFactory {
    fun create(driver: String, url: String): Conn = when (driver) {
        "pg"    -> PgConn(url)
        "mysql" -> MySQLConn(url)
        else    -> error("unknown driver $driver")
    }
}

// callers:
// val conn = ConnFactory.create(cfg.driver, cfg.url)
```
```dart
abstract interface class Conn { String get kind; }

class PgConn implements Conn {
  final String url;
  PgConn(this.url);
  @override String get kind => 'pg';
}

class MySQLConn implements Conn {
  final String url;
  MySQLConn(this.url);
  @override String get kind => 'mysql';
}

Conn createConn(String driver, String url) => switch (driver) {
  'pg'    => PgConn(url),
  'mysql' => MySQLConn(url),
  _       => throw ArgumentError('unknown driver $driver'),
};

// callers:
// final conn = createConn(cfg['driver']!, cfg['url']!);
```
```swift
protocol Conn { var kind: String { get } }

struct PgConn: Conn { let url: String; var kind: String { "pg" } }
struct MySQLConn: Conn { let url: String; var kind: String { "mysql" } }

enum ConnFactory {
    static func create(driver: String, url: String) -> any Conn {
        switch driver {
        case "pg":    return PgConn(url: url)
        case "mysql": return MySQLConn(url: url)
        default:      fatalError("unknown driver \(driver)")
        }
    }
}

// callers:
// let conn = ConnFactory.create(driver: cfg.driver, url: cfg.url)
```

## Framework idiom
- Spring Boot: prefer `@Bean` methods in a `@Configuration` class over a hand-rolled factory.
- .NET Core: prefer a typed factory delegate or `IServiceProvider`; avoid hand-rolled switch factories.
- Laravel: prefer the container `make()` / model factories over a hand-rolled factory.
- Android/Kotlin: prefer Hilt `@Provides`/`@Binds` in a `@Module` over a hand-rolled factory.
- Flutter/Dart: `get_it` registrations can replace a hand-rolled factory; use `registerFactory` for new instances.
- Swift/iOS: no framework-specific idiom; use an `enum` with a static `create` method or a DI container.

## Before / After
Before: `new MySQLConn()` / `new PgConn()` chosen inline in many modules.
After:
```ts
interface Conn { query(sql: string): Promise<Row[]> }

export function createConn(cfg: DbConfig): Conn {
  switch (cfg.driver) {
    case "pg": return new PgConn(cfg.url);
    case "mysql": return new MySQLConn(cfg.url);
    default: throw new Error(`unknown driver ${cfg.driver}`);
  }
}

// callers:
const conn = createConn(cfg);
```

## Verification focus
Same concrete type chosen for each input config; no behavior change in the
constructed object's methods.

## Pitfalls
Don't add a factory for a single stable constructor (YAGNI). Don't let the
factory leak concrete types in its return signature.
