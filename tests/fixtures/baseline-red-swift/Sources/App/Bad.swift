// Intentionally broken: a compile-time type error so `swift build` fails
// (router swift branch -> exit 2). This proves the safety harness refuses
// to operate on a red baseline.
func bad() -> Int {
    let n: Int = "no" // cannot convert value of type 'String' to type 'Int'
    return n
}
