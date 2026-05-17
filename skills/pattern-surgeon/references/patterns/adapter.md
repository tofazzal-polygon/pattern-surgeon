# Adapter

## Smell signature
A 3rd-party library API is called directly across many modules, its signature
mismatches the domain, and swapping the library would touch every call site.
Example:
```ts
// in checkout.ts, refund.ts, subscription.ts ...
await stripe.charges.create({ amount, currency, source });
```

## When NOT to apply
- The library is used in exactly one place.
- The library API already matches the domain shape closely.
- A thin pass-through wrapper would add indirection but no value.

## Transform recipe
1. Define a domain `Port` interface expressing what the app needs, in app terms.
2. Implement one `XAdapter implements Port` that wraps the library calls.
3. Convert library shapes ↔ domain shapes inside the adapter only.
4. Callers depend on `Port`; the adapter is wired at the composition root.

```python
from typing import Protocol


class PaymentPort(Protocol):
    # domain terms: dollars in, returns vendor charge id-equivalent (cents charged)
    def charge(self, amount_dollars: float, currency: str) -> int: ...


def vendor_charge(cents: int, currency: str) -> int:
    # fake 3rd-party vendor API: works in integer cents + lowercase->uppercase code
    return cents


class StripeAdapter:
    def charge(self, amount_dollars: float, currency: str) -> int:
        # convert domain shape -> vendor shape inside the adapter only
        cents = round(amount_dollars * 100)
        return vendor_charge(cents, currency.upper())


# callers depend on PaymentPort; adapter wired at the composition root:
# payments: PaymentPort = StripeAdapter()
```
```java
// domain terms: dollars in, returns vendor charge equivalent (cents charged)
interface PaymentPort {
    int charge(double dollars, String currency);
}

final class VendorApi {
    // fake 3rd-party vendor API: works in integer cents + uppercase code
    static int vendorCharge(int cents, String currency) {
        return cents;
    }
}

final class StripeAdapter implements PaymentPort {
    public int charge(double dollars, String currency) {
        // convert domain shape -> vendor shape inside the adapter only
        int cents = (int) Math.round(dollars * 100);
        return VendorApi.vendorCharge(cents, currency.toUpperCase());
    }
}

// callers depend on PaymentPort; adapter wired at the composition root:
// PaymentPort payments = new StripeAdapter();
```
```csharp
using System;

// domain terms: dollars in, returns vendor charge equivalent (cents charged)
interface IPaymentPort {
    int Charge(double dollars, string currency);
}

static class VendorApi {
    // fake 3rd-party vendor API: works in integer cents + uppercase code
    public static int VendorCharge(int cents, string currency) => cents;
}

sealed class StripeAdapter : IPaymentPort {
    public int Charge(double dollars, string currency) {
        // convert domain shape -> vendor shape inside the adapter only
        int cents = (int)Math.Round(dollars * 100);
        return VendorApi.VendorCharge(cents, currency.ToUpperInvariant());
    }
}

// callers depend on IPaymentPort; adapter wired at the composition root:
// IPaymentPort payments = new StripeAdapter();
```
```php
declare(strict_types=1);

// domain terms: dollars in, returns vendor charge equivalent (cents charged)
interface PaymentPort {
    public function charge(float $dollars, string $currency): int;
}

final class VendorApi {
    // fake 3rd-party vendor API: works in integer cents + uppercase code
    public static function vendorCharge(int $cents, string $currency): int {
        return $cents;
    }
}

final class StripeAdapter implements PaymentPort {
    public function charge(float $dollars, string $currency): int {
        // convert domain shape -> vendor shape inside the adapter only
        $cents = (int) round($dollars * 100);
        return VendorApi::vendorCharge($cents, strtoupper($currency));
    }
}

// callers depend on PaymentPort; adapter wired at the composition root:
// $payments = new StripeAdapter();
```

## Framework idiom
- Spring Boot: no framework-specific idiom; the adapter is a normal `@Component`.
- .NET Core: no framework-specific idiom; register the adapter against its port interface in DI.
- Laravel: no framework-specific idiom; bind the port to the adapter in a ServiceProvider.

## Before / After
Before: `stripe.charges.create(...)` sprinkled everywhere.
After:
```ts
interface PaymentPort {
  charge(input: { cents: number; currency: string; token: string }): Promise<{ id: string }>;
}

class StripeAdapter implements PaymentPort {
  constructor(private stripe: Stripe) {}
  async charge(i: { cents: number; currency: string; token: string }) {
    const c = await this.stripe.charges.create({
      amount: i.cents, currency: i.currency, source: i.token,
    });
    return { id: c.id };
  }
}

// callers:
await payments.charge({ cents, currency, token });
```

## Verification focus
Same external calls and results for existing inputs; field mapping preserved.

## Pitfalls
Don't mirror the library 1:1 — the port models the domain, not the vendor.
A port that just renames vendor methods provides no decoupling.
