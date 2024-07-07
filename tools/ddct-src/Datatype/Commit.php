<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

final class Commit
{
    public function __construct(
        public readonly string $id,
    ) {
    }

    public function __toString(): string
    {
        return $this->id;
    }

    public static function parse(string $value): ?self
    {
        if (!ctype_xdigit($value)) {
            return null;
        }

        if (strlen($value) > 40) {
            return null;
        }

        return new self($value);
    }

    public static function match(self $a, self $b): bool
    {
        return (
            str_starts_with($a->id, $b->id) ||
            str_starts_with($b->id, $a->id)
        );
    }
}
