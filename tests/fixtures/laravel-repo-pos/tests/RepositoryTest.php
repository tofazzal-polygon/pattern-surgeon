<?php

declare(strict_types=1);

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../src.php';

final class RepositoryTest extends TestCase
{
    public function testActivatesPendingUser(): void
    {
        $svc = new UserActivationService();
        self::assertSame('active', $svc->activate('u3'));
    }

    public function testActivatingAnAlreadyActiveUserIsIdempotent(): void
    {
        $svc = new UserActivationService();
        self::assertSame('active', $svc->activate('u1'));
    }

    public function testBannedUserCannotBeActivated(): void
    {
        $svc = new UserActivationService();
        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('banned');
        $svc->activate('u2');
    }

    public function testUnknownUserNotFound(): void
    {
        $svc = new UserActivationService();
        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('not found');
        $svc->activate('nope');
    }
}
