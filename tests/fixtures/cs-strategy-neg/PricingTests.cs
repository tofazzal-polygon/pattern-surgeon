using App;
using Xunit;

namespace Tests;

public class PricingTests
{
    [Fact]
    public void Toggle()
    {
        Assert.Equal(100.0, Pricing.Price(100, false), 4);
        Assert.Equal(90.0, Pricing.Price(100, true), 4);
    }

    [Fact]
    public void SelfTestPasses() => Assert.Equal(0, SelfTest.Run());
}
