<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

use DlangDockerized\Ddct\Util\ContainerFile;

final class ContainerFileMap
{

    public function __construct(
        private readonly AppVersionAppList $data,
    ) {
    }

    public function has(string $name, VersionSpecifier $version): bool
    {
        return ($this->get($name, $version) !== null);
    }

    public function get(string $name, VersionSpecifier $version): ?ContainerFileRecipe
    {
        $appVersionList = $this->data->get($name);
        if ($appVersionList === null) {
            return null;
        }

        return $appVersionList->match($version);
    }

    public function getByKey(string $key, bool $parseLax = true): ?ContainerFileRecipe
    {
        $parsedKey = ContainerFile::parseKey($key);
        if ($parsedKey === false) {
            return null;
        }

        $version = VersionSpecifier::parse($parsedKey[1], $parseLax);

        if ($version === null) {
            return null;
        }

        return $this->get($parsedKey[0], $version);
    }

    public static function parseDefinitions(array $definitions): self
    {
        $tree = new AppVersionAppList();
        foreach ($definitions as $key => $recipeRaw) {
            $keyData = ContainerFile::parseKey($key);
            $appName = $keyData[0];
            $appVersion = $keyData[1];
            $version = VersionSpecifier::parse($appVersion);

            if ($version->isNull()) {
                writeln('Warning: Ignoring Containerfile recipe with invalid version specifier `', $key, '`.');
                continue;
            }

            $appVersionList = $tree->get($appVersion);

            // Run duplicate check, if app already exists.
            if ($appVersionList !== null){
                if ($appVersionList->has($version)) {
                    writeln('Warning: Skipping duplicate or ambiguous Containerfile recipe entry `', $key, '`.');
                    continue;
                }
            }

            $recipe = ContainerFileRecipe::fromAA($recipeRaw, $appName, $appVersion);
            $entry = new ContainerFileMapEntry($version, $recipe);
            $tree->push($appName, $entry);
        }

        $tree->sort();
        return new ContainerFileMap($tree);
    }
}
