<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

use DlangDockerized\Ddct\Path;
use Exception;

final class BaseImage
{
    private static ?array $definitions = null;

    public function __construct(
        public readonly string $alias,
        public readonly string $image,
        public readonly array $env = [],
    ) {
    }

    private static function getDefinitions(): array
    {
        if (self::$definitions === null) {
            self::$definitions = IniLoader::load(Path::baseImageDefinitionsFile);
        }

        return self::$definitions;
    }

    public static function resolve(string $alias): BaseImage
    {
        $defs = self::getDefinitions();
        return self::resolveImpl($defs, $alias);
    }

    private static function resolveImpl(array $baseImages, string $alias): BaseImage
    {
        if (!isset($baseImages[$alias])) {
            throw new Exception('The requested base-image `' . $alias . '` is not available.');
        }

        $resolved = $baseImages[$alias];

        // resolve aliases
        if (isset($resolved['alias'])) {
            return self::resolveImpl($baseImages, $resolved['alias']);
        }

        if (!isset($resolved['image'])) {
            throw new Exception('Invalid base-image definition `' . $alias . '` specifies neither `image` nor `alias`.');
        }

        $env = (isset($resolved['env'])) ? $resolved['env'] : [];
        return new BaseImage($alias, $resolved['image'], $env);
    }
}
