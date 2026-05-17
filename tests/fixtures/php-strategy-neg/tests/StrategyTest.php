<?php

declare(strict_types=1);

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../src.php';

final class StrategyTest extends TestCase
{
    public function testStandardShipping(): void
    {
        self::assertSame(105.0, shipping_fee(false, 100.0));
    }

    public function testExpressShipping(): void
    {
        self::assertSame(115.0, shipping_fee(true, 100.0));
    }
}
