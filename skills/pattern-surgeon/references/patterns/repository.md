# Repository

## Smell signature
Raw ORM/SQL/`fetch` data access lives inline inside services, UI, or business
logic; query strings are interleaved with domain rules. Example:
```ts
async function activate(id: string) {
  const row = await db.query("SELECT * FROM users WHERE id = $1", [id]);
  if (!row) throw new Error("not found");
  if (row.status === "banned") throw new Error("banned");
  await db.query("UPDATE users SET status='active' WHERE id=$1", [id]);
}
```

## When NOT to apply
- Data access is already behind a data-access layer.
- A one-off script or migration with no domain logic.
- A trivial single query with no logic coupling and no reuse.

## Transform recipe
1. Define `interface UserRepository` in domain terms (no SQL, no ORM types).
2. Move all data access into a concrete implementation of it.
3. Inject the repository into services; services hold only rules.

```python
from dataclasses import dataclass, replace
from typing import Protocol


@dataclass
class User:
    id: str
    status: str


class UserRepository(Protocol):
    def find_by_id(self, id: str) -> User | None: ...
    def save(self, u: User) -> None: ...


class InMemoryUserRepository:
    def __init__(self) -> None:
        self._store: dict[str, User] = {}

    def find_by_id(self, id: str) -> User | None:
        return self._store.get(id)

    def save(self, u: User) -> None:
        self._store[u.id] = replace(u)


def activate(id: str, users: UserRepository) -> None:
    # service holds only rules; depends on the Protocol, not the store
    u = users.find_by_id(id)
    if u is None:
        raise LookupError("not found")
    if u.status == "banned":
        raise ValueError("banned")
    users.save(replace(u, status="active"))
```
```java
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

record User(String id, String status) {}

interface UserRepository {
    Optional<User> findById(String id);
    void save(User u);
}

final class InMemoryUserRepository implements UserRepository {
    private final Map<String, User> store = new HashMap<>();

    public Optional<User> findById(String id) {
        return Optional.ofNullable(store.get(id));
    }

    public void save(User u) {
        store.put(u.id(), u);
    }
}

final class UserService {
    private final UserRepository users;

    UserService(UserRepository users) {
        // service holds only rules; depends on the interface, not the store
        this.users = users;
    }

    void activate(String id) {
        User u = users.findById(id)
            .orElseThrow(() -> new RuntimeException("not found"));
        if (u.status().equals("banned")) throw new RuntimeException("banned");
        users.save(new User(u.id(), "active"));
    }
}
```
```csharp
using System;
using System.Collections.Generic;

record User(string Id, string Status);

interface IUserRepository {
    User? FindById(string id);
    void Save(User u);
}

sealed class InMemoryUserRepository : IUserRepository {
    private readonly Dictionary<string, User> _store = new();

    public User? FindById(string id) =>
        _store.TryGetValue(id, out var u) ? u : null;

    public void Save(User u) => _store[u.Id] = u;
}

sealed class UserService {
    private readonly IUserRepository _users;

    // service holds only rules; depends on the interface, not the store
    public UserService(IUserRepository users) { _users = users; }

    public void Activate(string id) {
        var u = _users.FindById(id) ?? throw new InvalidOperationException("not found");
        if (u.Status == "banned") throw new InvalidOperationException("banned");
        _users.Save(u with { Status = "active" });
    }
}
```
```php
declare(strict_types=1);

final class User {
    public function __construct(public string $id, public string $status) {}
}

interface UserRepository {
    public function findById(string $id): ?User;
    public function save(User $u): void;
}

final class InMemoryUserRepository implements UserRepository {
    /** @var array<string,User> */
    private array $store = [];

    public function findById(string $id): ?User {
        return $this->store[$id] ?? null;
    }

    public function save(User $u): void {
        $this->store[$u->id] = new User($u->id, $u->status);
    }
}

final class UserService {
    // service holds only rules; depends on the interface, not the store
    public function __construct(private UserRepository $users) {}

    public function activate(string $id): void {
        $u = $this->users->findById($id);
        if ($u === null) {
            throw new \RuntimeException('not found');
        }
        if ($u->status === 'banned') {
            throw new \RuntimeException('banned');
        }
        $this->users->save(new User($u->id, 'active'));
    }
}
```

```kotlin
data class User(val id: String, val status: String)

interface UserRepository {
    fun findById(id: String): User?
    fun save(u: User)
}

class InMemoryUserRepository : UserRepository {
    private val store = mutableMapOf<String, User>()
    override fun findById(id: String): User? = store[id]
    override fun save(u: User) { store[u.id] = u }
}

class UserService(private val users: UserRepository) {
    // service holds only rules; depends on the interface, not the store
    fun activate(id: String) {
        val u = users.findById(id) ?: error("not found")
        require(u.status != "banned") { "banned" }
        users.save(u.copy(status = "active"))
    }
}
```
```dart
class User {
  final String id;
  final String status;
  const User({required this.id, required this.status});
  User copyWith({String? status}) => User(id: id, status: status ?? this.status);
}

abstract interface class UserRepository {
  User? findById(String id);
  void save(User u);
}

class InMemoryUserRepository implements UserRepository {
  final _store = <String, User>{};
  @override User? findById(String id) => _store[id];
  @override void save(User u) { _store[u.id] = u; }
}

class UserService {
  final UserRepository _users;
  // service holds only rules; depends on the interface, not the store
  UserService(this._users);

  void activate(String id) {
    final u = _users.findById(id);
    if (u == null) throw StateError('not found');
    if (u.status == 'banned') throw StateError('banned');
    _users.save(u.copyWith(status: 'active'));
  }
}
```
```swift
struct User { let id: String; var status: String }

protocol UserRepository {
    func findById(_ id: String) -> User?
    func save(_ u: User)
}

class InMemoryUserRepository: UserRepository {
    private var store: [String: User] = [:]
    func findById(_ id: String) -> User? { store[id] }
    func save(_ u: User) { store[u.id] = u }
}

enum ActivateError: Error { case notFound, banned }

class UserService {
    private let users: any UserRepository
    // service holds only rules; depends on the protocol, not the store
    init(users: any UserRepository) { self.users = users }

    func activate(id: String) throws {
        guard var u = users.findById(id) else { throw ActivateError.notFound }
        guard u.status != "banned" else { throw ActivateError.banned }
        u.status = "active"
        users.save(u)
    }
}
```

## Framework idiom
- Spring Boot: extend Spring Data `JpaRepository<T,ID>`; do not hand-roll a DAO.
- .NET Core: use EF Core `DbContext`/`DbSet<T>` (optionally a repository over it).
- Laravel: use an Eloquent model or a repository bound in a ServiceProvider; do not bypass Eloquent.
- Android/Kotlin: use Room DAO + the Architecture Components repository pattern; do not bypass Room with raw SQL.
- Flutter/Dart: wrap `drift` (SQLite) or Firestore access behind the repository interface; do not call the DB directly from business logic.
- Swift/iOS: wrap Core Data `NSManagedObjectContext` or SwiftData `ModelContext` behind the protocol; do not call the context directly from the UI layer.

## Before / After
Before: `await db.query("SELECT ...")` inside the service.
After:
```ts
interface User { id: string; status: string }
interface UserRepository {
  findById(id: string): Promise<User | null>;
  save(u: User): Promise<void>;
}

async function activate(id: string, users: UserRepository) {
  const u = await users.findById(id);
  if (!u) throw new Error("not found");
  if (u.status === "banned") throw new Error("banned");
  await users.save({ ...u, status: "active" });
}
```

## Verification focus
Same data returned and persisted; identical query results for existing call
paths (round-trip a known id and compare).

## Pitfalls
Don't leak ORM/row types through the interface — keep it domain-shaped, or the
abstraction becomes useless when the ORM changes.
