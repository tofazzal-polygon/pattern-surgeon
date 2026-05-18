import 'package:test/test.dart';

// Intentionally failing test so `dart test` exits 1 (exit 3 — tests FAILED).
// This proves the safety harness refuses to operate on a red baseline.
void main() {
  test('always fails', () {
    expect(1, equals(2));
  });
}
