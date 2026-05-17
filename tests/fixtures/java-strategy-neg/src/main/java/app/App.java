package app;

// NOT a Strategy candidate: a single 2-branch boolean toggle at exactly one
// call site. Fewer than 3 cases and no duplication -> applying Strategy here
// would be over-engineering (see strategy.md "When NOT to apply").
public final class App {
    public static double price(double base, boolean discounted) {
        if (discounted) {
            return base * 0.9;
        }
        return base;
    }
}
