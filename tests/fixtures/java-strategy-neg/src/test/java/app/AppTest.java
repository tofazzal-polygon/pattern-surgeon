package app;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class AppTest {
    @Test
    void toggle() {
        assertEquals(100.0, App.price(100, false), 0.0001);
        assertEquals(90.0, App.price(100, true), 0.0001);
    }
}
