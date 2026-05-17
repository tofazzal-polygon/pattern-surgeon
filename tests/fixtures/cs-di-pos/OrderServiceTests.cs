using App;
using Xunit;

namespace Tests;

public class OrderServiceTests
{
    [Fact]
    public void PlaceRecordsOrder()
    {
        var svc = new OrderService();
        svc.Place("o-1");
        Assert.Single(svc.Placed);
        Assert.Equal("o-1", svc.Placed[0]);
    }

    [Fact]
    public void SelfTestPasses() => Assert.Equal(0, SelfTest.Run());
}
