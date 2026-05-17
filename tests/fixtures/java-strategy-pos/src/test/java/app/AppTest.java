package app;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class AppTest {
    @Test
    void priceBranches() {
        assertEquals(100.0, App.price("regular", 100), 0.0001);
        assertEquals(80.0, App.price("vip", 100), 0.0001);
        assertEquals(50.0, App.price("staff", 100), 0.0001);
    }
}
