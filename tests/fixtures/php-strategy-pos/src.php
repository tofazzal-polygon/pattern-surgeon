<?php

declare(strict_types=1);

// Strategy smell: the same >=3-branch pricing conditional is duplicated
// across two call sites (checkout + invoice). Branches differ only by the
// pricing algorithm for a given customer kind.

function checkout_total(string $kind, float $base): float
{
    if ($kind === 'regular') {
        return $base;
    }
    if ($kind === 'vip') {
        return $base * 0.8;
    }
    if ($kind === 'staff') {
        return $base * 0.5;
    }
    throw new InvalidArgumentException("unknown kind $kind");
}

function invoice_line(string $kind, float $base): float
{
    // duplicated branch logic — second site
    if ($kind === 'regular') {
        return $base;
    }
    if ($kind === 'vip') {
        return $base * 0.8;
    }
    if ($kind === 'staff') {
        return $base * 0.5;
    }
    throw new InvalidArgumentException("unknown kind $kind");
}
