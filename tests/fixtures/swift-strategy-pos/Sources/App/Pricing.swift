// Strategy pattern applied: protocol + per-variant structs + dictionary dispatch.
public protocol PricingStrategy { func price(base: Double) -> Double }

public struct Regular: PricingStrategy { public func price(base: Double) -> Double { base } }
public struct Vip:     PricingStrategy { public func price(base: Double) -> Double { base * 0.8 } }
public struct Staff:   PricingStrategy { public func price(base: Double) -> Double { base * 0.5 } }

private let strategies: [String: any PricingStrategy] = [
    "regular": Regular(), "vip": Vip(), "staff": Staff(),
]

public func price(kind: String, base: Double) -> Double {
    guard let s = strategies[kind] else { fatalError("unknown kind: \(kind)") }
    return s.price(base: base)
}

public func discountedTotal(kind: String, base: Double, qty: Int) -> Double {
    price(kind: kind, base: base) * Double(qty)
}
