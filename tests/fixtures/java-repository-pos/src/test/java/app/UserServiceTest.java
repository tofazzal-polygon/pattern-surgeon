package app;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class UserServiceTest {
    @Test
    void displayNameBehavior() {
        UserService svc = new UserService();
        assertEquals("alice", svc.displayName(1));
        assertEquals("bob (inactive)", svc.displayName(2));
        assertThrows(IllegalArgumentException.class, () -> svc.displayName(99));
    }
}
