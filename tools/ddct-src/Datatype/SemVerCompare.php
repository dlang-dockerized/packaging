<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

trait SemVerCompare
{
    private static function compareComponent(?int $a, ?int $b): int
    {
        return ($a ?? PHP_INT_MAX) <=> ($b ?? PHP_INT_MAX);
    }

    public static function compare(self $a, self $b): int
    {
        $major = self::compareComponent($a->major, $b->major);
        if ($major !== 0) {
            return $major;
        }

        $minor = self::compareComponent($a->minor, $b->minor);
        if ($minor !== 0) {
            return $minor;
        }

        $patch = self::compareComponent($a->patch, $b->patch);
        if ($patch !== 0) {
            return $patch;
        }

        $preReA = ($a->preRelease === null) ? 1 : 0;
        $preReB = ($b->preRelease === null) ? 1 : 0;
        $preRelease = $preReA <=> $preReB;
        if ($preRelease !== 0) {
            return $preRelease;
        }

        // both non-preReleases?
        if ($a->preRelease !== null) {
            return strnatcmp($a->preRelease, $b->preRelease);
        }

        if (isset($a->baseImageAlias)) {
            $baseImageAlias = strnatcmp($a->baseImageAlias, $b->baseImageAlias);
            if ($baseImageAlias !== 0) {
                return $baseImageAlias;
            }
        }

        return 0;
    }

    public function compareTo(self $b): int
    {
        return self::compare($this, $b);
    }
}
