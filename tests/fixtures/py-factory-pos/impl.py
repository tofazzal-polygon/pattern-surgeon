# SMELL: construction switches on a `driver` string. The same `XConn()`
# selection is conceptually repeated at multiple call spots. Candidate for Factory.


class MySQLConn:
    kind = "mysql"

    def ping(self) -> str:
        return "mysql-pong"


class PgConn:
    kind = "pg"

    def ping(self) -> str:
        return "pg-pong"


class SqliteConn:
    kind = "sqlite"

    def ping(self) -> str:
        return "sqlite-pong"


def create_conn(driver: str):
    if driver == "mysql":
        return MySQLConn()
    elif driver == "pg":
        return PgConn()
    elif driver == "sqlite":
        return SqliteConn()
    raise ValueError("unknown driver: " + driver)
