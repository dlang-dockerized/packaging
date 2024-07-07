<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

use http\Exception\InvalidArgumentException;
use LogicException;

final class VersionSpecifier
{
    public function __construct(
        public readonly VersionSpecifierType $type,
        public readonly ?Branch $branch,
        public readonly ?Commit $commit,
        public readonly ?SemVer $semanticTag,
    ) {
        $value = match ($this->type) {
            VersionSpecifierType::Null => true,
            VersionSpecifierType::Branch => $this->branch,
            VersionSpecifierType::Commit => $this->commit,
            VersionSpecifierType::SemanticTag => $this->semanticTag,
        };

        if ($value === null) {
            throw new LogicException('The provided type does not match the provided value.');
        }
    }

    public function __toString(): string
    {
        return (string)$this->getValue();
    }

    public function isBranch(): bool
    {
        return ($this->type === VersionSpecifierType::Branch);
    }

    public function isCommit(): bool
    {
        return ($this->type === VersionSpecifierType::Commit);
    }

    public function isSemantic(): bool
    {
        return ($this->type === VersionSpecifierType::SemanticTag);
    }

    public function isNull(): bool
    {
        return ($this->type === VersionSpecifierType::Null);
    }

    public function getValue(): null|Branch|Commit|SemVer
    {
        return match ($this->type) {
            VersionSpecifierType::Null => null,
            VersionSpecifierType::Branch => $this->branch,
            VersionSpecifierType::Commit => $this->commit,
            VersionSpecifierType::SemanticTag => $this->semanticTag,
        };
    }

    public static function make(mixed $value): self
    {
        if ($value instanceof Branch) {
            return new self(VersionSpecifierType::Branch, $value, null, null);
        }

        if ($value instanceof Commit) {
            return new self(VersionSpecifierType::Commit, null, $value, null);
        }

        if ($value instanceof SemVer) {
            return new self(VersionSpecifierType::SemanticTag, null, null, $value);
        }

        if ($value === null) {
            return new self(VersionSpecifierType::Null, null, null, null);
        }

        throw new InvalidArgumentException('Value must be null|Branch|Commit|SemVer.');
    }

    public static function parse(string $value, bool $parseSemanticVersionLax = false): self
    {
        $parsed = ($parseSemanticVersionLax)
            ? SemVer::parseLax($value)
            : SemVer::parse($value);
        if ($parsed !== null) {
            return new self(VersionSpecifierType::SemanticTag, null, null, $parsed);
        }

        $parsed = Branch::parse($value);
        if ($parsed !== null) {
            return new self(VersionSpecifierType::Branch, $parsed, null, null,);
        }

        $parsed = Commit::parse($value);
        if ($parsed !== null) {
            return new self(VersionSpecifierType::Commit, null, $parsed, null,);
        }

        return new self(VersionSpecifierType::Null, null, null, null);
    }

    private static function prioritizeByType(self $value): int
    {
        return match ($value->type) {
            VersionSpecifierType::Null => 0,
            VersionSpecifierType::Branch => 3,
            VersionSpecifierType::Commit => 1,
            VersionSpecifierType::SemanticTag => 2,
        };
    }

    public static function match(self $a, self $b): bool
    {
        if ($a->type !== $b->type) {
            return false;
        }

        return match ($a->type) {
            VersionSpecifierType::Null => true,
            VersionSpecifierType::Branch => Branch::match($a->branch, $b->branch),
            VersionSpecifierType::Commit => Commit::match($a->commit, $b->commit),
            VersionSpecifierType::SemanticTag => SemVer::match($a->semanticTag, $b->semanticTag),
        };
    }

    public static function compare(self $a, self $b): int
    {
        if ($a->type !== $b->type) {
            $na = self::prioritizeByType($a);
            $nb = self::prioritizeByType($b);
            return ($na <=> $nb);
        }

        return match ($a->type) {
            VersionSpecifierType::Null => 0,
            default => $a->getValue()->compareTo($b->getValue()),
        };
    }

    public function compareTo(self $b): int
    {
        return self::compare($this, $b);
    }
}
