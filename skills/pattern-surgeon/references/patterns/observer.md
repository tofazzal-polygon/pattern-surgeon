# Observer

## Smell signature
Manual cross-object notification chains, callback fan-out, or polling a flag to
detect state change; adding a new reaction means editing the producer. Example:
```ts
class Order {
  complete() {
    this.status = "done";
    emailService.send(this);   // producer knows every consumer
    analytics.track(this);
    inventory.release(this);
  }
}
```

## When NOT to apply
- There is a single listener (just call it directly).
- The framework is already reactive (RxJS, signals, `EventTarget`).
- A synchronous one-shot callback is sufficient.

## Transform recipe
1. Introduce a subject: `subscribe(listener)` and `notify(event)`.
2. Producer emits a domain event instead of calling consumers.
3. Consumers register themselves; producer no longer imports them.

```python
from typing import Callable, Generic, TypeVar

E = TypeVar("E")
Listener = Callable[[E], None]


class Subject(Generic[E]):
    def __init__(self) -> None:
        self._ls: list[Listener[E]] = []

    def subscribe(self, listener: Listener[E]) -> Callable[[], None]:
        self._ls.append(listener)

        def unsubscribe() -> None:
            self._ls = [x for x in self._ls if x is not listener]

        return unsubscribe

    def notify(self, event: E) -> None:
        for listener in list(self._ls):
            listener(event)


# producer emits a domain event instead of calling consumers:
order_completed: Subject[dict] = Subject()
# order_completed.subscribe(lambda o: email_service.send(o))
# order_completed.subscribe(lambda o: analytics.track(o))


class Order:
    def __init__(self) -> None:
        self.status = "open"

    def complete(self) -> None:
        self.status = "done"
        order_completed.notify({"order": self})
```
```java
import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

final class Subject<E> {
    private final List<Consumer<E>> ls = new ArrayList<>();

    Runnable subscribe(Consumer<E> l) {
        ls.add(l);
        return () -> ls.remove(l);
    }

    void notify(E e) {
        for (Consumer<E> l : new ArrayList<>(ls)) l.accept(e);
    }
}

final class Order {
    String status = "open";
    private final Subject<Order> orderCompleted;

    Order(Subject<Order> orderCompleted) {
        this.orderCompleted = orderCompleted;
    }

    void complete() {
        this.status = "done";
        orderCompleted.notify(this);   // producer no longer imports consumers
    }
}

// producer emits a domain event instead of calling consumers:
// Subject<Order> orderCompleted = new Subject<>();
// Runnable off = orderCompleted.subscribe(o -> emailService.send(o));
// orderCompleted.subscribe(o -> analytics.track(o));
// off.run(); // unsubscribe handle kept and called to avoid listener leaks
```
```csharp
using System;
using System.Collections.Generic;

sealed class Subject<E> {
    private readonly List<Action<E>> _ls = new();

    public Action Subscribe(Action<E> l) {
        _ls.Add(l);
        return () => _ls.Remove(l);
    }

    public void Notify(E e) {
        foreach (var l in new List<Action<E>>(_ls)) l(e);
    }
}

sealed class Order {
    public string Status = "open";
    private readonly Subject<Order> _orderCompleted;

    public Order(Subject<Order> orderCompleted) {
        _orderCompleted = orderCompleted;
    }

    public void Complete() {
        Status = "done";
        _orderCompleted.Notify(this);   // producer no longer imports consumers
    }
}

// producer emits a domain event instead of calling consumers:
// var orderCompleted = new Subject<Order>();
// Action off = orderCompleted.Subscribe(o => emailService.Send(o));
// orderCompleted.Subscribe(o => analytics.Track(o));
// off(); // unsubscribe handle kept and called to avoid listener leaks
```
```php
// TODO(phase-4): php example
```

## Framework idiom
- Spring Boot: prefer `ApplicationEventPublisher` + `@EventListener` over a hand-rolled subject.
- .NET Core: prefer `IObservable<T>`/events or `MediatR` notifications over a hand-rolled subject.
- Laravel: prefer Laravel Events & Listeners over a hand-rolled subject.

## Before / After
Before: `Order.complete()` calls `emailService` / `analytics` / `inventory`.
After:
```ts
type Listener<E> = (e: E) => void;

class Subject<E> {
  private ls: Listener<E>[] = [];
  subscribe(l: Listener<E>): () => void {
    this.ls.push(l);
    return () => { this.ls = this.ls.filter((x) => x !== l); };
  }
  notify(e: E) { for (const l of this.ls) l(e); }
}

const orderCompleted = new Subject<Order>();
orderCompleted.subscribe((o) => emailService.send(o));
orderCompleted.subscribe((o) => analytics.track(o));

class Order {
  complete() { this.status = "done"; orderCompleted.notify(this); }
}
```

## Verification focus
Every previously-notified party still reacts, in the same order if order
mattered.

## Pitfalls
Beware listener leaks — keep and call the unsubscribe handle. Don't introduce
an async event bus where a direct call suffices.
