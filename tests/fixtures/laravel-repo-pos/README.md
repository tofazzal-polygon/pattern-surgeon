# laravel-repo-pos

Pattern-surgeon fixture exercising the **Repository** smell in a Laravel-shaped
project.

## Router behaviour

`composer.json` + an `artisan` file makes `verify.sh` resolve:

```
detected stack=composer
TEST="php artisan test"
```

(The `artisan` branch is checked before the `vendor/bin/phpunit` branch.)

## Why this fixture is detection + static E2E only

A full Laravel application cannot bootstrap offline without the complete
`vendor/` dependency tree, and these fixtures are intentionally kept
lockless / vendorless (`vendor/` and `composer.lock` are git-ignored). So:

- `artisan` here is an executable **stub**: it exists purely so the marker
  router selects the Laravel test command. Invoking it exits non-zero
  gracefully (it never pretends to have run a real suite).
- The actual Repository smell lives in `src.php` (raw `DB::` access mixed
  into `UserActivationService`) and is statically exercised by the PHPUnit
  test in `tests/RepositoryTest.php`, which runs without the framework
  runtime if `php` + `phpunit` are available.

So this fixture asserts two things: (1) the verify router *detects* a Laravel
project and *would* run `php artisan test`, and (2) the smell + corrected
behaviour are statically checkable. Running the full `php artisan test`
offline is expected to fail gracefully (non-zero, no crash).
