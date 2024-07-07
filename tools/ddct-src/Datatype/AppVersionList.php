<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

final class AppVersionList
{
    public function __construct(
        /** @var ContainerFileMapEntry[] */
        public array $branches = [],

        /** @var ContainerFileMapEntry[] */
        public array $commits = [],

        /** @var ContainerFileMapEntry[] */
        public array $semanticTags = [],
    ) {
    }

    public function sort(): void
    {
        // Sort tags
        usort($this->semanticTags, function (ContainerFileMapEntry $a, ContainerFileMapEntry $b) {
            return SemVer::compare($b->version->semanticTag, $a->version->semanticTag);
        });
        // No way to sort branches and commits (yet).
    }

    public function has(VersionSpecifier $specifier): bool
    {
        return match ($specifier->type) {
            VersionSpecifierType::Null => false,
            VersionSpecifierType::Branch => $this->hasBranch($specifier->branch),
            VersionSpecifierType::Commit => $this->hasCommit($specifier->commit),
            VersionSpecifierType::SemanticTag => $this->hasSemanticTag($specifier->semanticTag),
        };
    }

    public function hasBranch(Branch $branch): bool
    {
        foreach ($this->branches as $b) {
            if ($b->version->branch->name === $branch->name) {
                return true;
            }
        }

        return false;
    }

    public function hasCommit(Commit $commit): bool
    {
        foreach ($this->commits as $c) {
            if (
                str_starts_with($c->version->commit->id, $commit->id) ||
                str_starts_with($commit->id, $c->version->commit->id)
            ) {
                return true;
            }
        }

        return false;
    }

    public function hasSemanticTag(SemVer $semanticTag): bool
    {
        foreach ($this->semanticTags as $st) {
            if (SemVer::compare($st->version->semanticTag, $semanticTag) === 0) {
                return true;
            }
        }

        return false;
    }

    public function match(VersionSpecifier $specifier): ?ContainerFileRecipe
    {
        return match ($specifier->type) {
            VersionSpecifierType::Null => null,
            VersionSpecifierType::Branch => $this->matchBranch($specifier->branch),
            VersionSpecifierType::Commit => $this->matchCommit($specifier->commit),
            VersionSpecifierType::SemanticTag => $this->matchSemanticTag($specifier->semanticTag),
        };
    }

    public function matchSemanticTag(SemVer $semanticTag): ?ContainerFileRecipe
    {
        foreach ($this->semanticTags as $entry) {
            if (SemVer::match($entry->version->semanticTag, $semanticTag)) {
                return $entry->recipe;
            }
        }

        return null;
    }

    public function matchBranch(Branch $branch): ?ContainerFileRecipe
    {
        foreach ($this->branches as $b) {
            if ($b->version->branch->name === $branch->name) {
                return $b->recipe;
            }
        }

        return null;
    }

    public function matchCommit(Commit $commit): ?ContainerFileRecipe
    {
        foreach ($this->commits as $c) {
            if (
                str_starts_with($c->version->commit->id, $commit->id) ||
                str_starts_with($commit->id, $c->version->commit->id)
            ) {
                return $c->recipe;
            }
        }

        return null;
    }

    public function push(ContainerFileMapEntry $entry): void
    {
        match ($entry->version->type) {
            VersionSpecifierType::Null => null,
            VersionSpecifierType::Branch => $this->branches[] = $entry,
            VersionSpecifierType::Commit => $this->commits[] = $entry,
            VersionSpecifierType::SemanticTag => $this->semanticTags[] = $entry,
        };
    }
}
