package app

import org.junit.Test
import org.junit.Assert.assertEquals

class PricingTest {
    @Test fun `regular price unchanged`() = assertEquals(100.0, price("regular", 100.0), 0.001)
    @Test fun `vip gets 20 percent off`() = assertEquals(80.0, price("vip", 100.0), 0.001)
    @Test fun `staff gets 50 percent off`() = assertEquals(50.0, price("staff", 100.0), 0.001)
    @Test fun `discounted total for vip`() = assertEquals(160.0, discountedTotal("vip", 100.0, 2), 0.001)
}
