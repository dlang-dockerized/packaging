<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

use DlangDockerized\Ddct\Datatype\AAWrapper;
use DlangDockerized\Ddct\Datatype\BaseImage;
use DlangDockerized\Ddct\Datatype\ContainerFileRecipe;
use DlangDockerized\Ddct\Datatype\VersionSpecifier;
use DlangDockerized\Ddct\Path;
use Exception;

class ContainerFile
{
    private static ?TemplateEngine $templateEngine = null;

    private function __construct()
    {
    }

    private static function getTemplateEngine(): TemplateEngine
    {
        if (self::$templateEngine === null) {
            self::$templateEngine = new TemplateEngine(Path::templatesDir);
        }

        return self::$templateEngine;
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

    public static function getContainerFileTargetDir(
        string $appName,
        string $appVersion,
        BaseImage $baseImage,
    ): string {
        return Path::containerFilesOutputDir . '/' . $appName . '/' . $appVersion . '/' . $baseImage->alias;
    }

    public static function getContainerFileTargetPath(
        string $appName,
        string $appVersion,
        BaseImage $baseImage,
    ): string {
        $dir = self::getContainerFileTargetDir($appName, $appVersion, $baseImage);
        return $dir . '/Containerfile';
    }

    public static function generateFile(string $appName, string $appVersion, string $baseImageAlias): string
    {
        $baseImage = BaseImage::resolve($baseImageAlias);
        $recipe = self::loadRecipe($appName, $appVersion);
        $version = VersionSpecifier::parse($appVersion);

        $containerFileDir = self::getContainerFileTargetDir($appName, $appVersion, $baseImage);
        $containerFilePath = $containerFileDir . '/Containerfile';

        // Create target dir (if not exists)
        if (!file_exists($containerFileDir)) {
            mkdir($containerFileDir, 0o755, true);
        }

        $tplVars = array_merge($recipe->env, $baseImage->env);

        $varsDerivator = new VariablesDerivator($appName, $version, $baseImage);
        $varsDerivator->applyVariables(function (string $key, mixed $value) use (&$tplVars) {
            $tplVars[$key] = $value;
        });

        $templateEngine = self::getTemplateEngine();
        $templateEngine->executeToFile($recipe->template, $tplVars, $containerFilePath);
        return $containerFilePath;
    }
}
