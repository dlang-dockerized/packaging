<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

final class ContainerVersionTag
{
    public function __construct(
        public VersionSpecifier $versionSpecifier,
        public ?string $baseImageAlias = null,
    ) {
    }

    public function __toString(): string
    {
        return $this->toString(true);
    }

    public function toString(bool $includeBaseImageAlias): string
    {
        return match ($this->versionSpecifier->type) {
            VersionSpecifierType::Null => ($includeBaseImageAlias)
                ? '_-' . $this->baseImageAlias
                : '_',

            VersionSpecifierType::Branch => $this->toStringImplGeneric(
                (string)$this->versionSpecifier->branch,
                $includeBaseImageAlias
            ),

            VersionSpecifierType::Commit => $this->toStringImplGeneric(
                (string)$this->versionSpecifier->commit,
                $includeBaseImageAlias
            ),

            VersionSpecifierType::SemanticTag => $this->toStringImplSemanticTag($includeBaseImageAlias),
        };
    }

    private function toStringImplSemanticTag(bool $includeBaseImageAlias): string
    {
        $semver = $this->versionSpecifier->semanticTag;
        $s = (string)$semver->major;
        $s .= '.' . ($semver->minor ?? '*');
        $s .= '.' . ($semver->patch ?? '*');

        if ($semver->preRelease !== null) {
            $s .= '_' . $semver->preRelease;
        }

        if ($includeBaseImageAlias && ($this->baseImageAlias !== null)) {
            $s .= '-' . $this->baseImageAlias;
        }

        return $s;
    }

    private function toStringImplGeneric(string $data, bool $includeBaseImageAlias): string
    {
        $data = str_replace('-', '_', $data);

        if ($includeBaseImageAlias && ($this->baseImageAlias !== null)) {
            return $data . '-' . $this->baseImageAlias;
        }
        return $data;
    }

    public function isFullVersionNumber(): bool
    {
        return match ($this->versionSpecifier->type) {
            VersionSpecifierType::Null => false,
            VersionSpecifierType::Branch => $this->versionSpecifier->branch->name !== '',
            VersionSpecifierType::Commit => $this->versionSpecifier->commit->id !== '',
            VersionSpecifierType::SemanticTag => (
                ($this->versionSpecifier->semanticTag->minor !== null) &&
                ($this->versionSpecifier->semanticTag->patch !== null)
            ),
        };
    }

    public static function compare(self $a, self $b): int
    {
        $naive = VersionSpecifier::compare($a->versionSpecifier, $b->versionSpecifier);

        if ($naive === 0) {
            if ($a->baseImageAlias !== $b->baseImageAlias) {
                if ($a->baseImageAlias === null) {
                    return 1;
                }
                if ($b->baseImageAlias === null) {
                    return -1;
                }

                return strnatcmp($a->baseImageAlias, $b->baseImageAlias);
            }
        }

        return $naive;
    }

    public function compareTo(self $b): int
    {
        return self::compare($this, $b);
    }

    public static function match(self $a, self $b): bool
    {
        $naive = VersionSpecifier::match($a->versionSpecifier, $b->versionSpecifier);
        if (!$naive) {
            return false;
        }

        if (($a->baseImageAlias === null) || ($b->baseImageAlias === null)) {
            return true;
        }

        return ($a->baseImageAlias === $b->baseImageAlias);
    }

    public static function fromSemVer(SemVer $semver, ?string $baseImageAlias = null): self
    {
        return new self(
            VersionSpecifier::make($semver),
            $baseImageAlias
        );
    }

    public static function fromVersionSpecifier(
        VersionSpecifier $versionSpecifier,
        ?string $baseImageAlias = null
    ): self {
        return new self(
            $versionSpecifier,
            $baseImageAlias,
        );
    }

    public static function parse(string $input): ?self
    {
        return self::parseImpl($input, false);
    }

    public static function parseLax(string $input): ?self
    {
        return self::parseImpl($input, true);
    }

    private static function parseImpl(string $input, bool $lax): ?self
    {
        if (!self::parseValidateAndConsumeBaseImageAlias($input, $baseImageAlias)) {
            return null;
        }

        $type = self::parseDetermineType($input);
        $parsed = match ($type) {
            VersionSpecifierType::Null => null,
            VersionSpecifierType::Branch => Branch::parse($input),
            VersionSpecifierType::Commit => Commit::parse($input),
            VersionSpecifierType::SemanticTag => self::parseSemantic($input, $lax),
        };

        if ($parsed === null) {
            return null;
        }

        return new self(
            VersionSpecifier::make($parsed),
            $baseImageAlias,
        );
    }

    private static function parseSemantic(string $input, bool $lax): ?SemVer
    {
        if ($lax) {
            $match = preg_match(
                '/^(?P<major>\d*)'
                . '(?:\.(?P<minor>[\d*]*))?'
                . '(?:\.(?P<patch>[\d*]*))?'
                . '(?:_(?P<prerelease>[0-9a-zA-Z_.]+))?$/',
                $input,
                $matches,
                PREG_UNMATCHED_AS_NULL,
            );
        } else {
            $match = preg_match(
                '/^(?P<major>0|[1-9]\d*)'
                . '\.(?P<minor>0|[1-9]\d*)'
                . '\.(?P<patch>0|[1-9]\d*)'
                . '(?:_(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z_][0-9a-zA-Z_]*)'
                . '(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z_][0-9a-zA-Z_]*))*))?$/',
                $input,
                $matches,
                PREG_UNMATCHED_AS_NULL,
            );
        }

        if (($match === false) || ($match === 0)) {
            return null;
        }

        $major = ($matches['major'] === null) ? null : (int)$matches['major'];
        $minor = ($matches['minor'] === null) ? null : (int)$matches['minor'];
        $patch = ($matches['patch'] === null) ? null : (int)$matches['patch'];

        return new SemVer(
            $major,
            $minor,
            $patch,
            $matches['prerelease'] ?? null,
        );
    }

    private static function parseValidateAndConsumeBaseImageAlias(string &$input, ?string &$baseImageAlias): bool
    {
        $idxSep = strpos($input, '-');
        if ($idxSep === false) {
            return true;
        }

        $baseImageAlias = substr($input, $idxSep + 1);
        $valid = preg_match('/^[0-9a-zA-Z_-]+$/', $baseImageAlias);
        if (!$valid) {
            return false;
        }

        $input = substr($input, 0, $idxSep);
        return true;
    }

    private static function parseDetermineType(string $inputWithNoBaseImageAlias): VersionSpecifierType
    {
        $input = &$inputWithNoBaseImageAlias;

        $containsDot = strpos($input, '.');
        if ($containsDot !== false) {
            return VersionSpecifierType::SemanticTag;
        }

        $isNumeric = ctype_digit($input);
        $length = strlen($input);

        // "Beware, guess-work ahead."
        // Treat purely numeric strings as semantic tag, unless they are 7+ chars.
        // This is the default-ish length for short hashes in Git.
        if ($isNumeric && $length < 7) {
            return VersionSpecifierType::SemanticTag;
        }

        $isHex = ctype_digit($input);
        if ($isHex && $length <= 40) {
            return VersionSpecifierType::Commit;
        }

        return VersionSpecifierType::Branch;
    }
}
