<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct;

use DlangDockerized\Ddct\Datatype\BaseImage;
use DlangDockerized\Ddct\Datatype\ContainerFileMap;
use DlangDockerized\Ddct\Datatype\ContainerImage;
use DlangDockerized\Ddct\Datatype\ContainerVersionTag;
use DlangDockerized\Ddct\Datatype\UserBuildSelection;
use DlangDockerized\Ddct\Datatype\VersionSpecifier;
use DlangDockerized\Ddct\Util\BuildSelector;
use DlangDockerized\Ddct\Util\ContainerBuilder;
use DlangDockerized\Ddct\Util\ContainerBuilderStatus;
use DlangDockerized\Ddct\Util\ContainerEngine;
use DlangDockerized\Ddct\Util\ContainerFile;
use DlangDockerized\Ddct\Util\ContainerFileDefinitions;
use DlangDockerized\Ddct\Util\PackagerInfo;
use DlangDockerized\Ddct\Util\Tagger;
use Exception;

final class App
{
    public function run(int $argc, array $argv): int
    {
        try {
            return $this->runCommand($argc, $argv);
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
            'build-selection' => $this->buildSelection($argc, $argv),
            'can-build' => $this->canBuild($argc, $argv),
            'detect-engine' => $this->detectEngine($argc, $argv),
            'generate' => $this->generate($argc, $argv),
            'generate-all' => $this->generateAll($argc, $argv),
            'has-built' => $this->hasBuilt($argc, $argv),
            'help', '--help' => $this->help($argc, $argv),
            'namespace-copy' => $this->namespaceCopy($argc, $argv),
            'namespace-echo' => $this->namespaceEcho($argc, $argv),
            'namespace-publish' => $this->namespacePublish($argc, $argv),
            'namespace-remove-all' => $this->namespaceRemoveAll($argc, $argv),
            'tag' => $this->tag($argc, $argv),

            default => $this->notACommand($userCommand),
        };
    }

    private function notACommand(string $userCommand): int
    {
        errorln("`{$userCommand}` is not a ddct command.");
        return 1;
    }

    private function help(int $argc, array $argv): int
    {
        if ($argc !== 2) {
            errorln('Too many arguments.');
            return 1;
        }

        writeln(
            'dlang-dockerized Container Toolkit',
            "\n\nAvailable commands:\n",
            "  build                   - Build a specific container image.\n",
            "  build-selection         - Build the defined selection of container images.\n",
            "  can-build               - Determine whether a container image is available for building.\n",
            "  detect-engine           - Detect which container management engine will be used.\n",
            "  generate-all            - Generate all Containerfiles from the templates.\n",
            "  generate                - Generate a specific Containerfile from the templates.\n",
            "  has-built               - Check whether a certain container image has been built and is available.\n",
            "  help                    - Print this help text.\n",
            "  namespace-copy          - Copy all images from the current namespace to another.\n",
            "  namespace-echo          - Print the current namespace.\n",
            "  namespace-publish       - Publish the current namespace to the \n",
            "  namespace-remove-all    - Remove all container images from the current namespace (by tag).\n",
            "  tag                     - Update the tags of all container images within the current namespace.\n",
        );
        return 0;
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

        $version = VersionSpecifier::parse($appVersion, true);
        if ($version === null) {
            errorln('Cannot parse the specified version string `', $appVersion, '`.');
            return 1;
        }

        $baseImage = BaseImage::resolve($baseImageAlias);

        $containerEngine = new ContainerEngine();
        $tagger = new Tagger($containerEngine);
        $containerBuilder = new ContainerBuilder($containerEngine, $map, $tagger);
        $buildStatus = $containerBuilder->build($appName, $version, $baseImage);

        if ($buildStatus === ContainerBuilderStatus::Preexists) {
            writeln('Nothing to do.');
        } elseif ($buildStatus === ContainerBuilderStatus::Built) {
            writeln('Done.');
        }

        return 0;
    }

    private function buildSelection(int $argc, array $argv): int
    {
        $hasSelectionFilePath = ($argc === 3);

        if (!$hasSelectionFilePath && ($argc !== 2)) {
            errorln('Too many arguments.');
            usageln($argv[0], 'build-selection [<selection.ini>]');
            return 1;
        }

        $selectionFilePath = ($hasSelectionFilePath)
            ? $argv[2]
            : Path::definitionsDir . '/build-selection.ini';

        $userBuildSelection = UserBuildSelection::loadFromFile($selectionFilePath);


        $map = ContainerFileMap::parseDefinitions(
            ContainerFileDefinitions::get()
        );

        $buildSelector = new BuildSelector($map);
        $machineSelection = $buildSelector->determineSelection($userBuildSelection);

        $containerEngine = new ContainerEngine();
        $tagger = new Tagger($containerEngine);
        $containerBuilder = new ContainerBuilder($containerEngine, $map, $tagger);

        foreach ($machineSelection as $triplet) {
            writeln('Building image `' . $triplet . '` from selection.');
            $buildStatus = $containerBuilder->buildByTriplet($triplet);

            if ($buildStatus === ContainerBuilderStatus::Preexists) {
                writeln('-> Nothing to do.');
            } elseif ($buildStatus === ContainerBuilderStatus::Built) {
                writeln('-> Done.');
            }
        }

        return 0;
    }

    private function canBuild(int $argc, array $argv): int
    {
        $argsOk = $this->readArgsAppNameVersionBaseimage(
            $argc,
            $argv,
            'can-build',
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

        $version = VersionSpecifier::parse($appVersion, true);
        if ($version->isNull()) {
            errorln('Cannot parse the specified version string `', $appVersion, '`.');
            return 1;
        }

        $recipe = $map->get($appName, $version);
        if ($recipe === null) {
            errorln('No recipe found for requested container `', $appName, '`:`', $version, '`');
            return 1;
        }

        outputln($recipe->app, ':', $recipe->version);

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

    private function namespaceRemoveAll(int $argc, array $argv): int
    {
        if ($argc !== 2) {
            errorln('Command `namespace-remove-all` does not support any arguments.');
            writeln('Hint: Use the environment variable `CONTAINER_NAMESPACE` to specify which namespace to expunge.');
            return 1;
        }

        $containerEngine = new ContainerEngine();
        $images = $containerEngine->listImages();

        // Don't touch non-dlang-dockerized images.
        $images = array_filter($images, function (ContainerImage $image) {
            return $image->isOurs();
        });

        $images = array_map('strval', $images);

        // No duplicates.
        $images = array_unique($images);

        $containerEngine->removeImages(false, ...$images);
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
            usageln($argv[0], 'generate-all [<base-image>]');
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

    private function hasBuilt(int $argc, array $argv): int
    {
        $argsOk = $this->readArgsAppNameVersionBaseimage(
            $argc,
            $argv,
            'has-built',
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

        $version = VersionSpecifier::parse($appVersion, true);
        if ($version === null) {
            errorln('Cannot parse the specified version string `', $appVersion, '`.');
            return 1;
        }

        $baseImage = BaseImage::resolve($baseImageAlias);
        $tagver = ContainerVersionTag::fromVersionSpecifier($version, $baseImage->alias);

        $containerEngine = new ContainerEngine();
        $tagger = new Tagger($containerEngine);
        $containerBuilder = new ContainerBuilder($containerEngine, $map, $tagger);
        $image = $containerBuilder->hasBuilt($appName, $tagver);

        if ($image === null) {
            return 1;
        }

        outputln($image);

        return 0;
    }

    private function namespaceCopy(int $argc, array $argv): int
    {
        if ($argc !== 3) {
            errorln('Invalid number of arguments.');
            usageln($argv[0], 'namespace-copy <target-repo-namespace>');
            return 1;
        }

        $namespaceSource = PackagerInfo::getContainerNamespace();
        $namespaceSourceLength = strlen($namespaceSource);
        $namespaceTarget = $argv[2];

        $containerEngine = new ContainerEngine();

        foreach ($containerEngine->listImages() as $imageSource) {
            // Is in <source> namespace?
            if ($imageSource->getNamespace() !== $namespaceSource) {
                continue;
            }

            $tagSource = $imageSource->tag;

            // No tag attached?
            if ($tagSource === null) {
                writeln('Warning: Skipping tag-less image entry `', $imageSource->id, '`.');
                continue;
            }

            $repoSource = $imageSource->repository;
            $repoTarget = substr_replace($repoSource, $namespaceTarget, 0, $namespaceSourceLength);

            $imageTarget = new ContainerImage(null, $repoTarget, $tagSource);
            $fullTagTarget = (string)$imageTarget;
            $fullTagSource = (string)$imageSource;

            outputln($fullTagTarget);
            $containerEngine->tagImage($fullTagSource, $fullTagTarget);
        }

        return 0;
    }

    private function namespaceEcho(int $argc, array $argv): int
    {
        if ($argc !== 2) {
            errorln('Command `echo` does not support any arguments.');
            return 1;
        }

        outputln(PackagerInfo::getContainerNamespace());
        return 0;
    }

    private function namespacePublish(int $argc, array $argv): int
    {
        if ($argc !== 2) {
            errorln('Command `namespace-publish` does not support any arguments.');
            return 1;
        }

        $containerEngine = new ContainerEngine();

        foreach ($containerEngine->listImages() as $image) {
            if (!$image->isOurs()) {
                continue;
            }

            if (!$image->hasFullName()) {
                writeln('Warning: Skipping image `', $image->id, '` with no full name.');
                continue;
            }

            $imageFullName = (string)$image;
            $containerEngine->pushImage($imageFullName);
        }

        return 0;
    }

    private function tag(int $argc, array $argv): int
    {
        $engine = new ContainerEngine();
        $tagger = new Tagger($engine);
        $tagger->applyAll();
        return 0;
    }
}
