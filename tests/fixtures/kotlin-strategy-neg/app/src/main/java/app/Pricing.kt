package app

// SMELL: same switch over kind repeated in multiple sites — Strategy candidate.
fun price(kind: String, base: Double): Double {
    if (kind == "regular") return base
    if (kind == "vip") return base * 0.8
    if (kind == "staff") return base * 0.5
    error("unknown kind: $kind")
}

fun discountedTotal(kind: String, base: Double, qty: Int): Double {
    val unit: Double
    if (kind == "regular") unit = base
    else if (kind == "vip") unit = base * 0.8
    else if (kind == "staff") unit = base * 0.5
    else error("unknown kind: $kind")
    return unit * qty
}
