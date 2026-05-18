package app

// Intentionally broken: type mismatch so kotlinc rejects the file.
// `compileDebugKotlin` (or `gradle compileDebugKotlin`) fails -> exit 2.
fun bad(): Int {
    val n: Int = "no" // type mismatch: inferred type is String but Int was expected
    return n
}
