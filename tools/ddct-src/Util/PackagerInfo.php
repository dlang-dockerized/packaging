<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

final class PackagerInfo
{
    private static ?string $containerNamespace = null;

    private function __construct()
    {
    }

    public static function getContainerNamespace(): string
    {
        if (self::$containerNamespace === null) {
            self::$containerNamespace = $_SERVER['CONTAINER_NAMESPACE'] ?? 'dlang-dockerized';
        }

        return self::$containerNamespace;
    }
}
