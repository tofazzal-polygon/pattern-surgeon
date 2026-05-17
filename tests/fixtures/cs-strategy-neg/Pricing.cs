using System;

namespace App;

// NOT a Strategy candidate: a single 2-branch boolean toggle at exactly one
// call site. Fewer than 3 cases and no duplication -> applying Strategy here
// would be over-engineering (see references/patterns/strategy.md
// "When NOT to apply").
public static class Pricing
{
    public static double Price(double @base, bool discounted)
    {
        if (discounted)
        {
            return @base * 0.9;
        }
        return @base;
    }
}
