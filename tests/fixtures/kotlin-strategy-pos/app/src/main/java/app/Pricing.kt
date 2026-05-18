package app

// Strategy pattern applied: one interface, one class per variant, map-based dispatch.
interface PricingStrategy { fun price(base: Double): Double }

object Regular : PricingStrategy { override fun price(base: Double) = base }
object Vip     : PricingStrategy { override fun price(base: Double) = base * 0.8 }
object Staff   : PricingStrategy { override fun price(base: Double) = base * 0.5 }

private val strategies = mapOf<String, PricingStrategy>(
    "regular" to Regular, "vip" to Vip, "staff" to Staff,
)

fun price(kind: String, base: Double): Double =
    strategies[kind]?.price(base) ?: error("unknown kind: $kind")

fun discountedTotal(kind: String, base: Double, qty: Int): Double =
    price(kind, base) * qty
