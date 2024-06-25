<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

use DlangDockerized\Ddct\Datatype\AAWrapper;
use DlangDockerized\Ddct\Datatype\BaseImage;
use DlangDockerized\Ddct\Datatype\ContainerFileRecipe;

use DlangDockerized\Ddct\Path;
use Exception;

class ContainerFile
{
    private function __construct()
    {
    }

    public static function parseKey(string $key): array|bool
    {
        $data = explode(':', $key, 2);

        if (count($data) !== 2) {
            return false;
        }

        return $data;
    }

    public static function loadRecipe(string $appName, string $appVersion): ContainerFileRecipe
    {
        $containerFile = $appName . ':' . $appVersion;
        $defs = new AAWrapper(ContainerFileDefinitions::get());

        if (!$defs->has($containerFile)) {
            throw new Exception('No recipe available for the requested Containerfile `' . $containerFile . '`.');
        }

        $recipe = $defs->get($containerFile);
        return ContainerFileRecipe::fromAA($recipe, $appName, $appVersion);
    }

    public static function generateFile($appName, $appVersion, $baseImageAlias): string
    {
        $baseImage = BaseImage::resolve($baseImageAlias);

        $recipe = self::loadRecipe($appName, $appVersion);

        $tplPath = Path::templatesDir . '/' . $recipe->template;
        $tpl = BashTpl::compile($tplPath);

        $containerFileDir = Path::containerFilesOutputDir . '/' . $appName . '/' . $appVersion . '/' . $baseImage->alias;
        $containerFilePath = $containerFileDir . '/Containerfile';

        // Create target dir (if not exists)
        if (!file_exists($containerFileDir)) {
            mkdir($containerFileDir, 0o755, true);
        }

        $tplVars = $recipe->env;
        $tplVars['BASE_IMAGE'] = $baseImage->image;
        $tplVars['BASE_IMAGE_ALIAS'] = $baseImage->alias;

        BashTpl::executeToFile($tpl, $tplVars, $containerFilePath);
        return $containerFilePath;
    }
}
