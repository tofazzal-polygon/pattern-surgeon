// Intentionally broken: dart analyze reports a static error.
// `dart analyze` exits non-zero (exit 2 — typecheck FAILED).
int bad() {
  int n = "no"; // A value of type 'String' can't be assigned to 'int'
  return n;
}
