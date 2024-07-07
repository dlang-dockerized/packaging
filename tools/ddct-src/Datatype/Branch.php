<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

final class Branch
{
    public function __construct(
        public readonly string $name,
    ) {
    }

    public function __toString(): string
    {
        return $this->name;
    }

    public static function parse(string $value): ?self
    {
        return match ($value) {
            'dev',
            'ltsmaster',
            'main',
            'master',
            'stable',
            'trunk' => new Branch($value),

            default => null
        };
    }

    public static function compare(Branch $a, Branch $b): int
    {
        $na = ($a->name === 'stable') ? 0 : 1;
        $nb = ($b->name === 'stable') ? 0 : 1;

        return $na <=> $nb;
    }

    public function compareTo(Branch $b): int
    {
        return self::compare($this, $b);
    }

    public static function match(self $a, self $b): bool
    {
        return ($a->name === $b->name);
    }
}
