<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

trait SemVerMatch
{
    private static function matchComponent(mixed $a, mixed $b): bool
    {
        if (($a === null) || ($b === null)) {
            return true;
        }

        return ($a === $b);
    }

    public static function match(self $a, self $b): bool
    {
        if (!self::matchComponent($a->major, $b->major)) {
            return false;
        }
        if (!self::matchComponent($a->minor, $b->minor)) {
            return false;
        }
        if (!self::matchComponent($a->patch, $b->patch)) {
            return false;
        }
        if (!self::matchComponent($a->preRelease, $b->preRelease)) {
            return false;
        }

        if (property_exists($a, 'buildMetadata')) {
            return self::matchComponent($a->buildMetadata, $b->buildMetadata);
        }

        return true;
    }
}
