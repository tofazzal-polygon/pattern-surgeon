<?php

declare(strict_types=1);

// Repository smell (Laravel flavour): raw query-builder / DB access is
// interleaved with domain rules directly inside the service class. Swapping
// the persistence mechanism or unit-testing the rules forces touching SQL.
//
// In a real Laravel app `DB` would be Illuminate\Support\Facades\DB. Offline
// we provide a minimal in-memory stand-in so the smell + behaviour can be
// statically exercised by PHPUnit without the framework runtime.

final class DB
{
    /** @var array<string,array<string,string>> */
    private static array $tables = [
        'users' => [
            'u1' => 'active',
            'u2' => 'banned',
            'u3' => 'pending',
        ],
    ];

    public static function selectStatus(string $table, string $id): ?string
    {
        return self::$tables[$table][$id] ?? null;
    }

    public static function updateStatus(string $table, string $id, string $status): void
    {
        self::$tables[$table][$id] = $status;
    }
}

final class UserActivationService
{
    public function activate(string $id): string
    {
        // SMELL: raw DB access mixed into business logic, no repository layer.
        $status = DB::selectStatus('users', $id);
        if ($status === null) {
            throw new RuntimeException('not found');
        }
        if ($status === 'banned') {
            throw new RuntimeException('banned');
        }
        DB::updateStatus('users', $id, 'active');

        return DB::selectStatus('users', $id);
    }
}
