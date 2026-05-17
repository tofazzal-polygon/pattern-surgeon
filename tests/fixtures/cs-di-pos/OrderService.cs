using System;
using System.Collections.Generic;

namespace App;

// A simple in-memory "database" collaborator.
public sealed class Db
{
    public readonly List<string> Inserted = new();
    public void Insert(string order) => Inserted.Add(order);
}

// SMELL: OrderService constructs its own collaborator internally
// (`new Db()`). The dependency is hidden and the class cannot be tested with
// a double without reaching into its internals. Candidate for Dependency
// Injection (see references/patterns/dependency-injection.md).
public sealed class OrderService
{
    private readonly Db _db = new Db(); // hidden, untestable

    public void Place(string order) => _db.Insert(order);

    // Exposed only so the smell's behavior can be asserted; in real code the
    // hidden dependency is exactly what makes this hard to verify.
    public IReadOnlyList<string> Placed => _db.Inserted;
}
