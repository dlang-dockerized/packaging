<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

use DlangDockerized\Ddct\Util\ContainerFile;

final class ContainerFileMap
{
    private readonly AAWrapper $data;

    public function __construct(
        array $sortedData,
    ) {
        $this->data = new AAWrapper($sortedData);
    }

    public function has(string $name, SemVer $version): bool
    {
        return ($this->get($name, $version) !== null);
    }

    public function get(string $name, SemVer $version): ?ContainerFileRecipe
    {
        $appEntries = $this->data->get($name);
        if ($appEntries === null) {
            return null;
        }

        foreach ($appEntries as $entry) {
            if (SemVer::match($entry->version, $version)) {
                return $entry->recipe;
            }
        }

        return null;
    }

    public static function parseDefinitions(array $definitions): self
    {
        $tree = new AAWrapper([]);
        foreach ($definitions as $key => $recipeRaw) {
            $keyData = ContainerFile::parseKey($key);
            $appName = $keyData[0];
            $appVersion = $keyData[1];
            $semver = SemVer::parse($appVersion);

            if ($semver === null) {
                writeln('Warning: Ignoring Containerfile recipe with invalid semver `', $key, '`.');
                continue;
            }

            $recipe = ContainerFileRecipe::fromAA($recipeRaw, $appName, $appVersion);

            // Run duplicate check, if app already exists.
            if ($tree->has($appName)) {
                foreach ($tree->get($appName) as $entry) {
                    if ($entry->recipe->version === $appVersion) {
                        writeln('Warning: Skipping duplicate Containerfile recipe entry `', $key, '`.');
                        continue 2;
                    }
                }
            }

            $entry = new ContainerFileMapEntry($semver, $recipe);
            $tree->push($appName, $entry);
        }

        $tree = $tree->getArray();
        foreach ($tree as &$appVersionList) {
            usort($appVersionList, function (ContainerFileMapEntry $a, ContainerFileMapEntry $b) {
                return SemVer::compare($b->version, $a->version);
            });
        }

        return new ContainerFileMap($tree);
    }
}
