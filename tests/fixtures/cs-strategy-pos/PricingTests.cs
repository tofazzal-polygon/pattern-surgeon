using App;
using Xunit;

namespace Tests;

public class PricingTests
{
    [Fact]
    public void PriceBranches()
    {
        Assert.Equal(100.0, Pricing.Price("regular", 100), 4);
        Assert.Equal(80.0, Pricing.Price("vip", 100), 4);
        Assert.Equal(50.0, Pricing.Price("staff", 100), 4);
    }

    // Mirror of the offline self-test path so both validation routes assert
    // identical behavior.
    [Fact]
    public void SelfTestPasses() => Assert.Equal(0, SelfTest.Run());
}
