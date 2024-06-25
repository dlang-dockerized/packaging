<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

use Stringable;

final class SemVer implements Stringable
{
    public function __construct(
        public int $major,
        public ?int $minor,
        public ?int $patch,
        public ?string $preRelease = null,
        public ?string $buildMetadata = null,
    ) {
    }

    public function __toString(): string
    {
        $s = (string)$this->major;
        $s .= '.' . ($this->minor ?? '*');
        $s .= '.' . ($this->patch ?? '*');

        if ($this->preRelease !== null) {
            $s .= '-' . $this->preRelease;
        }

        if ($this->buildMetadata !== null) {
            $s .= '+' . $this->buildMetadata;
        }

        return $s;
    }

    private static function compareComponent(?int $a, ?int $b): int
    {
        return ($a ?? PHP_INT_MAX) <=> ($b ?? PHP_INT_MAX);
    }

    public static function compare(SemVer $a, SemVer $b): int
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
        if ($a->preRelease === null) {
            return 0;
        }

        return strnatcmp($a->preRelease, $b->preRelease);
    }

    private static function matchComponent(?int $a, ?int $b): bool
    {
        if (($a === null) || ($b === null)) {
            return true;
        }

        return ($a === $b);
    }

    public static function match(SemVer $a, SemVer $b): bool
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
        return self::matchComponent($a->buildMetadata, $b->buildMetadata);
    }

    public static function parse(string $input): ?self
    {
        if (str_starts_with($input, 'v')) {
            $input = substr($input, 1);
        }

        $match = preg_match(
            '/^(?P<major>0|[1-9]\d*)'
            . '\.(?P<minor>0|[1-9]\d*)'
            . '\.(?P<patch>0|[1-9]\d*)'
            . '(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)'
            . '(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?'
            . '(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/',
            $input,
            $matches,
        );

        if (($match === false) || ($match === 0)) {
            return null;
        }

        return new SemVer(
            (int)$matches['major'],
            (int)$matches['minor'],
            (int)$matches['patch'],
            $matches['prerelease'] ?? null,
            $matches['buildmetadata'] ?? null,
        );
    }

    public static function parseLax(string $input): ?self
    {
        if (str_starts_with($input, 'v')) {
            $input = substr($input, 1);
        }

        $match = preg_match(
            '/^(?P<major>\d*)'
            . '(?:\.(?P<minor>[\d*]*))?'
            . '(?:\.(?P<patch>[\d*]*))?'
            . '(?:-(?P<prerelease>[0-9a-zA-Z-.]+))?'
            . '(?:\+(?P<buildmetadata>[0-9a-zA-Z-.]+))?$/',
            $input,
            $matches,
        );

        if (($match === false) || ($match === 0)) {
            return null;
        }

        $minor = $matches['minor'] ?? null;
        $minor = ($minor === null) ? null : (($minor !== '*') ? (int)$minor : null);
        $patch = $matches['patch'] ?? null;
        $patch = ($patch === null) ? null : (($patch !== '*') ? (int)$patch : null);

        return new SemVer(
            (int)$matches['major'],
            $minor,
            $patch,
            $matches['prerelease'] ?? null,
            $matches['buildmetadata'] ?? null,
        );
    }
}
