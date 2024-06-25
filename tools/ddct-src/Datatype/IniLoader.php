<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

use DlangDockerized\Ddct\Datatype\AAWrapper;
use Exception;

final class IniLoader
{
    /**
     * @throws Exception
     */
    public static function load(string $path): array
    {
        if (!file_exists($path)) {
            $baseName = basename($path);
            throw new Exception("Cannot load `{$baseName}`: File `{$path}` does not exist.");
        }

        $iniData = parse_ini_file($path, true, INI_SCANNER_RAW);
        if ($iniData === false) {
            $baseName = basename($path);
            throw new Exception("Bad `{$baseName}`: Invalid INI syntax.");
        }

        return $iniData;
    }
}
