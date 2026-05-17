# Real type error: assigning a str to an int-annotated name. This is a TYPE
# error (mypy catches it), not a syntax error -- the file parses fine.
x: int = "no"
