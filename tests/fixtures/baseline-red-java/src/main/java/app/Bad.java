package app;

// Intentionally broken: a compile-time type error so `mvn -q compile`
// fails (router maven branch -> exit 2). There is also NO src/test, so even
// if it compiled there would be no tests (-> exit 4). This proves the
// safety harness refuses to operate on a red baseline.
public final class Bad {
    public int value() {
        int n = "no"; // incompatible types: String cannot be converted to int
        return n;
    }
}
