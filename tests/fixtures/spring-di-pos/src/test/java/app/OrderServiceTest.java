package app;

import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

// Plain JUnit unit test (no Spring context boot needed).
class OrderServiceTest {
    @Test
    void producesAnOrderId() {
        OrderService svc = new OrderService();
        long a = svc.placeOrder();
        long b = svc.placeOrder();
        assertTrue(a > 0, "order id should be positive");
        assertNotEquals(a, b, "each order should get a fresh id");
    }
}
