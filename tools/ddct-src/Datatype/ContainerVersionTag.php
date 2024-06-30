<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

final class ContainerVersionTag
{
    use SemVerCompare, SemVerMatch;

    public function __construct(
        public int $major,
        public ?int $minor,
        public ?int $patch,
        public ?string $preRelease = null,
        public ?string $baseImageAlias = null,
    ) {
    }

    public function __toString(): string
    {
        return $this->toString(true);
    }

    public function toString(bool $includeBaseImageAlias): string
    {
        $s = (string)$this->major;
        $s .= '.' . ($this->minor ?? '*');
        $s .= '.' . ($this->patch ?? '*');

        if ($this->preRelease !== null) {
            $s .= '_' . $this->preRelease;
        }

        if ($includeBaseImageAlias && ($this->baseImageAlias !== null)) {
            $s .= '-' . $this->baseImageAlias;
        }

        return $s;
    }

    public function isFullVersionNumber(): bool
    {
        return (
            ($this->minor !== null)
            && ($this->patch !== null)
        );
    }

    public static function fromSemVer(SemVer $semver, ?string $baseImageAlias = null): self
    {
        return new self(
            $semver->major,
            $semver->minor,
            $semver->patch,
            $semver->preRelease,
            $baseImageAlias
        );
    }

    public static function parse(string $input): ?self
    {
        $match = preg_match(
            '/^(?P<major>0|[1-9]\d*)'
            . '\.(?P<minor>0|[1-9]\d*)'
            . '\.(?P<patch>0|[1-9]\d*)'
            . '(?:_(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z_][0-9a-zA-Z_]*)'
            . '(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z_][0-9a-zA-Z_]*))*))?'
            . '(?:-(?P<baseimagealias>[0-9a-zA-Z_-]+(?:\.[0-9a-zA-Z_-]+)*))?$/',
            $input,
            $matches,
            PREG_UNMATCHED_AS_NULL,
        );

        if (($match === false) || ($match === 0)) {
            return null;
        }

        return new self(
            (int)$matches['major'],
            (int)$matches['minor'],
            (int)$matches['patch'],
            $matches['prerelease'] ?? null,
            $matches['baseimagealias'] ?? null,
        );
    }

    public static function parseLax(string $input): ?self
    {
        $match = preg_match(
            '/^(?P<major>\d*)'
            . '(?:\.(?P<minor>[\d*]*))?'
            . '(?:\.(?P<patch>[\d*]*))?'
            . '(?:_(?P<prerelease>[0-9a-zA-Z_.]+))?'
            . '(?:-(?P<baseimagealias>[0-9a-zA-Z-_.]+))?$/',
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

        return new self(
            (int)$matches['major'],
            $minor,
            $patch,
            $matches['prerelease'] ?? null,
            $matches['baseimagealias'] ?? null,
        );
    }
}
