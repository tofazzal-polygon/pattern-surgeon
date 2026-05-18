// SMELL: same switch/if over kind repeated in two functions — Strategy candidate.
public func price(kind: String, base: Double) -> Double {
    if kind == "regular" { return base }
    if kind == "vip"     { return base * 0.8 }
    if kind == "staff"   { return base * 0.5 }
    fatalError("unknown kind: \(kind)")
}

public func discountedTotal(kind: String, base: Double, qty: Int) -> Double {
    let unit: Double
    switch kind {
    case "regular": unit = base
    case "vip":     unit = base * 0.8
    case "staff":   unit = base * 0.5
    default:        fatalError("unknown kind: \(kind)")
    }
    return unit * Double(qty)
}
