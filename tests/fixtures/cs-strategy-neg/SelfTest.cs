using System;

namespace App;

// Offline / toolchain-gated assertion harness. 0 = pass, 1 = fail.
// Documented static/gated validation route when xUnit + NuGet restore is
// unavailable. Invoked from the SelfTestPasses [Fact].
public static class SelfTest
{
    public static int Run()
    {
        if (!Eq(Pricing.Price(100, false), 100)) return Fail("not-discounted");
        if (!Eq(Pricing.Price(100, true), 90)) return Fail("discounted");
        return 0;
    }

    private static bool Eq(double a, double b) => Math.Abs(a - b) < 0.0001;

    private static int Fail(string what)
    {
        Console.Error.WriteLine($"cs-strategy-neg self-test FAILED: {what}");
        return 1;
    }
}
