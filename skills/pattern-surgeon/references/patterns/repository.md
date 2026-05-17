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
// TODO(phase-3): csharp example
```
```php
// TODO(phase-4): php example
```

## Framework idiom
- Spring Boot: extend Spring Data `JpaRepository<T,ID>`; do not hand-roll a DAO.
- .NET Core: use EF Core `DbContext`/`DbSet<T>` (optionally a repository over it).
- Laravel: use an Eloquent model or a repository bound in a ServiceProvider; do not bypass Eloquent.

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
