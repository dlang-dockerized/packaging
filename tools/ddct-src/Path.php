<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct;

final class Path
{
    public const definitionsDir = './definitions';
    public const baseImageDefinitionsFile = self::definitionsDir . '/baseimages.ini';
    public const containerFileDefinitionsFile = self::definitionsDir . '/containerfiles.ini';

    public const containerFilesOutputDir = './containerfiles';

    public const templatesDir = './templates';

    private function __construct()
    {
    }
}
