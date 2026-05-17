package app;

// SMELL: pricing logic branches on a `kind` string with >=3 cases. The same
// if/else cascade is conceptually duplicated wherever a price is computed
// (checkout + invoice). Candidate for Strategy.
public final class App {
    public static double price(String kind, double base) {
        if (kind.equals("regular")) {
            return base;
        }
        if (kind.equals("vip")) {
            return base * 0.8;
        }
        if (kind.equals("staff")) {
            return base * 0.5;
        }
        throw new IllegalArgumentException("unknown kind: " + kind);
    }
}
