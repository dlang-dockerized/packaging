<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

use DlangDockerized\Ddct\Path;
use Exception;

final class BaseImage
{
    public function __construct(
        public readonly string $alias,
        public readonly string $image,
    ) {
    }

    public static function loadDefinitions(): array
    {
        $ini = IniLoader::load(Path::baseImageDefinitionsFile);

        if (!isset($ini['base_images'])) {
            writeln('Warning: Using empty base-image definition file `', Path::baseImageDefinitionsFile, '`.');
            return [];
        }

        return $ini['base_images'];
    }

    public static function resolve(string $alias): BaseImage
    {
        $defs = self::loadDefinitions();
        return self::resolveImpl($defs, $alias);
    }

    private static function resolveImpl(array $baseImages, string $alias): BaseImage
    {
        if (!isset($baseImages[$alias])) {
            throw new Exception('The requested base-image `' . $alias . '` is not available.');
        }

        $resolved = $baseImages[$alias];

        // resolve aliases
        if (str_starts_with($resolved, 'alias:')) {
            return self::resolveImpl($baseImages, substr($resolved, 6));
        }

        return new BaseImage($alias, $resolved);
    }
}
