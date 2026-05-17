package app;

import java.util.concurrent.atomic.AtomicLong;

// In a Spring app this is a @Component / collaborator bean.
public final class IdGen {
    private final AtomicLong seq = new AtomicLong(1000);

    public long next() {
        return seq.incrementAndGet();
    }
}
