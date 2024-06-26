<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct;

use DlangDockerized\Ddct\Datatype\BaseImage;
use DlangDockerized\Ddct\Datatype\ContainerFileMap;
use DlangDockerized\Ddct\Datatype\ContainerTag;
use DlangDockerized\Ddct\Datatype\SemVer;
use DlangDockerized\Ddct\Util\BashTplException;
use DlangDockerized\Ddct\Util\ContainerEngine;
use DlangDockerized\Ddct\Util\ContainerFile;
use DlangDockerized\Ddct\Util\ContainerFileDefinitions;
use Exception;

final class App
{
    public function run(int $argc, array $argv): int
    {
        try {
            return $this->runCommand($argc, $argv);
        } catch (BashTplException $ex) {
            errorln($ex->getMessage());
            writeln($ex->details);
            return 1;
        } catch (Exception $ex) {
            errorln($ex->getMessage());
            return 1;
        }
    }

    private function runCommand(int $argc, array $argv): int
    {
        if ($argc < 2) {
            writeln('dlang-dockerized Container Toolkit');
            errorln('No command provided.');
            usageln($argv[0], '<command> [<args>...]');
            return 1;
        }

        $userCommand = strtolower($argv[1]);

        return match ($userCommand) {
            'build' => $this->build($argc, $argv),
            'detect-engine' => $this->detectEngine($argc, $argv),
            'generate' => $this->generate($argc, $argv),
            'generate-all' => $this->generateAll($argc, $argv),

            default => $this->notACommand($userCommand),
        };
    }

    private function notACommand(string $userCommand): int
    {
        errorln("`{$userCommand}` is not a ddct command.");
        return 1;
    }

    private function readArgsAppNameVersionBaseimage(
        int $argc,
        array $argv,
        string $command,
        ?string &$outAppName,
        ?string &$outAppVersion,
        ?string &$outBaseImageAlias
    ): bool {
        $usageArgs = $command . ' <app-name> <version> [<base-image>]';

        if ($argc < 3) {
            errorln('No app-name specified.');
            usageln($argv[0], $usageArgs);
            return false;
        }
        $outAppName = $argv[2];

        if ($argc < 4) {
            errorln('No version specified for app `', $outAppName, '`.');
            usageln($argv[0], $usageArgs);
            return false;
        }
        $outAppVersion = $argv[3];

        $outBaseImageAlias = ($argc >= 5) ? $argv[4] : 'default';

        return true;
    }

    private function build(int $argc, array $argv): int
    {
        $argsOk = $this->readArgsAppNameVersionBaseimage(
            $argc,
            $argv,
            'build',
            $appName,
            $appVersion,
            $baseImageAlias
        );

        if (!$argsOk) {
            return 1;
        }

        $map = ContainerFileMap::parseDefinitions(
            ContainerFileDefinitions::get()
        );
        $semver = SemVer::parseLax($appVersion);

        $recipe = $map->get($appName, $semver);
        if ($recipe === null) {
            errorln('No recipe found for requested container `', $appName, '`:`', $semver, '`');
            return 1;
        }

        writeln('Found `', $recipe->app, ':', $recipe->version, '`.');
        foreach ($recipe->dependencies as $dependency) {
            writeln('Depends on: ', $dependency);
        }

        if (count($recipe->dependencies) > 0) {
            // TODO
            errorln('Dependency resolution is not implemented yet.');
            return 1;
        }

        $baseImage = BaseImage::resolve($baseImageAlias);
        $containerFilePath = ContainerFile::getContainerFileTargetPath($recipe->app, $recipe->version, $baseImage);
        $tag = ContainerTag::makeFromRecipe($recipe, $baseImage);

        $engine = new ContainerEngine();
        $engine->build($containerFilePath, $tag);

        writeln('Done.');

        return 0;
    }

    private function detectEngine(int $argc, array $argv): int
    {
        try {
            $detected = ContainerEngine::detectContainerEngine();
        } catch (Exception) {
            return 1;
        }

        if ($detected === null) {
            return 1;
        }

        outputln($detected);
        return 0;
    }

    private function generate(int $argc, array $argv): int
    {
        $argsOk = $this->readArgsAppNameVersionBaseimage(
            $argc,
            $argv,
            'generate',
            $appName,
            $appVersion,
            $baseImageAlias
        );

        if (!$argsOk) {
            return 1;
        }

        $savedAs = ContainerFile::generateFile($appName, $appVersion, $baseImageAlias);
        writeln('Containerfile saved to `', $savedAs, '`.');
        return 0;
    }

    private function generateAll(int $argc, array $argv): int
    {
        if ($argc > 3) {
            errorln('Too many arguments.');
            usageln($argv[0], 'generateall [<base-image>]');
            return 1;
        }

        $baseImageAlias = ($argc >= 3) ? $argv[2] : 'default';

        $containerDefs = ContainerFileDefinitions::get();
        $error = false;
        foreach ($containerDefs as $key => $containerDef) {
            $app = ContainerFile::parseKey($key);
            if ($app === false) {
                errorln('Encountered invalid Containerfile recipe definition `' . $key . '`.');
                $error = true;
                continue;
            }

            writeln('Generating Containerfile for `', $key, '`.');
            $savedAs = ContainerFile::generateFile($app[0], $app[1], $baseImageAlias);
            writeln('Containerfile saved to `', $savedAs, '`.');
        }

        return ($error) ? 1 : 0;
    }
}
