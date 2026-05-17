using System;

namespace App;

// Intentionally broken: a compile-time type error so `dotnet build` fails
// (router dotnet branch -> exit 2). There is also NO test project, so even
// if it compiled there would be no tests (-> exit 4). This proves the safety
// harness refuses to operate on a red baseline.
public static class Program
{
    public static int Main()
    {
        int n = "no"; // CS0029: cannot implicitly convert string to int
        return n;
    }
}
