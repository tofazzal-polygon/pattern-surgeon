using System;

namespace App;

// Offline / toolchain-gated assertion harness. 0 = pass, 1 = fail.
// Documented static/gated validation route when xUnit + NuGet restore is
// unavailable. Invoked from the SelfTestPasses [Fact].
public static class SelfTest
{
    public static int Run()
    {
        var svc = new OrderService();
        svc.Place("o-1");
        if (svc.Placed.Count != 1) return Fail("count");
        if (svc.Placed[0] != "o-1") return Fail("value");
        return 0;
    }

    private static int Fail(string what)
    {
        Console.Error.WriteLine($"cs-di-pos self-test FAILED: {what}");
        return 1;
    }
}
