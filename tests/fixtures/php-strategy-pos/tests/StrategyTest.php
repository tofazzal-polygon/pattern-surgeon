<?php

declare(strict_types=1);

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../src.php';

final class StrategyTest extends TestCase
{
    public function testCheckoutPricing(): void
    {
        self::assertSame(100.0, checkout_total('regular', 100.0));
        self::assertSame(80.0, checkout_total('vip', 100.0));
        self::assertSame(50.0, checkout_total('staff', 100.0));
    }

    public function testInvoicePricingMatchesCheckout(): void
    {
        self::assertSame(100.0, invoice_line('regular', 100.0));
        self::assertSame(80.0, invoice_line('vip', 100.0));
        self::assertSame(50.0, invoice_line('staff', 100.0));
    }

    public function testUnknownKindThrows(): void
    {
        $this->expectException(InvalidArgumentException::class);
        checkout_total('ghost', 100.0);
    }
}
