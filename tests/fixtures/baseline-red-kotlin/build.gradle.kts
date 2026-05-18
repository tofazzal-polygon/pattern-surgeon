// Pattern-surgeon baseline-red fixture for Kotlin/Android.
// This minimal build file triggers android-kotlin stack detection via
// the AndroidManifest.xml marker. The gradlew wrapper is absent so
// verify.sh falls back to `gradle`, which is also absent, causing
// compileDebugKotlin to fail (exit 2 — typecheck FAILED). This proves
// the safety harness refuses to operate on a red baseline.
plugins {
    id("com.android.application")
    kotlin("android")
}
