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

    public static function parseLax(string $input): ?self
    {
        if (str_starts_with($input, 'v')) {
            $input = substr($input, 1);
        }

        $match = preg_match(
            '/^(?P<major>\d*)'
            . '(?:\.(?P<minor>[\d*]*))?'
            . '(?:\.(?P<patch>[\d*]*))?'
            . '(?:_(?P<prerelease>[0-9a-zA-Z_.]+))?'
            . '(?:-(?P<baseimagealias>[0-9a-zA-Z-_.]+))?$/',
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
        $preRelease = empty($matches['prerelease']) ? null : $matches['prerelease'];

        return new self(
            (int)$matches['major'],
            $minor,
            $patch,
            $preRelease,
            $matches['baseimagealias'] ?? null,
        );
    }
}
