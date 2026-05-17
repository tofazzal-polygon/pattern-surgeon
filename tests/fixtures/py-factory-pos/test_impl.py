from impl import create_conn


def test_create_conn_kinds():
    assert create_conn("mysql").kind == "mysql"
    assert create_conn("pg").kind == "pg"
    assert create_conn("sqlite").kind == "sqlite"
    assert create_conn("pg").ping() == "pg-pong"
