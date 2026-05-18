import XCTest
@testable import App

final class PricingTests: XCTestCase {
    func testRegularUnchanged()   { XCTAssertEqual(price(kind: "regular", base: 100), 100.0) }
    func testVipTwentyOff()       { XCTAssertEqual(price(kind: "vip",     base: 100),  80.0) }
    func testStaffFiftyOff()      { XCTAssertEqual(price(kind: "staff",   base: 100),  50.0) }
    func testDiscountedTotalVip() { XCTAssertEqual(discountedTotal(kind: "vip", base: 100, qty: 2), 160.0) }
}
