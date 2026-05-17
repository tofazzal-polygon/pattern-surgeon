using System;

namespace App;

// Offline / toolchain-gated assertion harness. When the xUnit + NuGet restore
// path is available, PricingTests drives `dotnet test`. When it is not (no
// dotnet / no cache), Run() reproduces the exact same assertions and returns
// a process-style exit code: 0 = pass, 1 = fail. A trivial Main wrapper is
// intentionally NOT added here because this project is a test SDK project
// (its entrypoint is owned by the test host); Run() is invoked from the
// SelfTestPasses [Fact] and is the documented static/gated validation route.
public static class SelfTest
{
    public static int Run()
    {
        if (!Eq(Pricing.Price("regular", 100), 100)) return Fail("regular");
        if (!Eq(Pricing.Price("vip", 100), 80)) return Fail("vip");
        if (!Eq(Pricing.Price("staff", 100), 50)) return Fail("staff");
        return 0;
    }

    private static bool Eq(double a, double b) => Math.Abs(a - b) < 0.0001;

    private static int Fail(string what)
    {
        Console.Error.WriteLine($"cs-strategy-pos self-test FAILED: {what}");
        return 1;
    }
}
