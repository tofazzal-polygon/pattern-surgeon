<?php

declare(strict_types=1);

// Intentional, real PHP parse error: malformed function signature.
// `php -l` MUST report a syntax/parse error on this file.

function x( { }
