package app;

import java.util.HashMap;
import java.util.Map;

// SMELL: data-access logic is inlined directly inside the service. The
// "table" lookup, row-shaping, and the not-found handling are mixed with
// business logic. Candidate for the Repository pattern (extract a
// UserRepository so the service depends on an abstraction, not raw rows).
public final class UserService {
    // Stands in for a JDBC-backed table. In a real app this would be a
    // Connection/PreparedStatement against a "users" table.
    private final Map<Integer, String> rows = new HashMap<>();

    public UserService() {
        rows.put(1, "alice|active");
        rows.put(2, "bob|disabled");
    }

    public String displayName(int id) {
        // raw "query" + row parsing inlined into the service:
        String row = rows.get(id);
        if (row == null) {
            throw new IllegalArgumentException("no such user: " + id);
        }
        String[] cols = row.split("\\|");
        String name = cols[0];
        String status = cols[1];
        // business logic tangled with the data access:
        if (status.equals("disabled")) {
            return name + " (inactive)";
        }
        return name;
    }
}
