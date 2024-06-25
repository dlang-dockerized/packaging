<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

use DlangDockerized\Ddct\Datatype\IniLoader;
use DlangDockerized\Ddct\Path;

class ContainerFileDefinitions
{
    private static ?array $definitions = null;

    private function __construct()
    {
    }

    public static function get(): array
    {
        if (self::$definitions === null) {
            self::$definitions = IniLoader::load(Path::containerFileDefinitionsFile);
        }

        return self::$definitions;
    }
}
