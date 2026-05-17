using System;

namespace App;

// SMELL: pricing logic branches on a `kind` string with >=3 cases. The same
// if/else cascade is conceptually duplicated wherever a price is computed
// (checkout + invoice). Candidate for Strategy (see references/patterns/strategy.md).
public static class Pricing
{
    public static double Price(string kind, double @base)
    {
        if (kind == "regular")
        {
            return @base;
        }
        if (kind == "vip")
        {
            return @base * 0.8;
        }
        if (kind == "staff")
        {
            return @base * 0.5;
        }
        throw new ArgumentException("unknown kind: " + kind);
    }
}
