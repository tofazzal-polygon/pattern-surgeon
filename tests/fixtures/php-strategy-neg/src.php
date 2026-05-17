<?php

declare(strict_types=1);

// NOT a Strategy smell: a single 2-branch boolean toggle at exactly one call
// site. Fewer than 3 cases and no duplication — extracting a strategy here
// would add indirection with no value (YAGNI).

function shipping_fee(bool $express, float $base): float
{
    if ($express) {
        return $base + 15.0;
    }

    return $base + 5.0;
}
