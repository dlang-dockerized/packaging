<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

use Stringable;

final class SemVer implements Stringable
{
    use SemVerCompare, SemVerMatch;

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

    public function toString(): string
    {
        return $this->__toString();
    }

    public function toDmString(): string
    {
        $s = (string)$this->major;
        $s .= '.' . $this->getMinorDm();
        $s .= '.' . ($this->patch ?? '*');

        if ($this->preRelease !== null) {
            $s .= '-' . $this->preRelease;
        }

        if ($this->buildMetadata !== null) {
            $s .= '+' . $this->buildMetadata;
        }

        return $s;
    }

    public function getMinorDm(): string
    {
        if ($this->minor === null) {
            return '*';
        }

        return sprintf('%03d', $this->minor);
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
            PREG_UNMATCHED_AS_NULL,
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
            PREG_UNMATCHED_AS_NULL,
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
