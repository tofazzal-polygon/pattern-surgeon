package app;

// In a Spring app this is a @Service.
//
// SMELL: the service constructs its own collaborator internally
// (`new IdGen()`) instead of receiving it via constructor injection. This
// hard-wires the dependency, blocks substitution in tests, and bypasses the
// Spring container. Candidate for Dependency Injection (inject IdGen as a
// constructor parameter / @Autowired bean).
public final class OrderService {
    private final IdGen id = new IdGen();

    public long placeOrder() {
        // business logic would go here; returns a freshly generated order id
        return id.next();
    }
}
