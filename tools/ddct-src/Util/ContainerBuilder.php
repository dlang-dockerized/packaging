<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

use DlangDockerized\Ddct\Datatype\BaseImage;
use DlangDockerized\Ddct\Datatype\ContainerFileMap;
use DlangDockerized\Ddct\Datatype\ContainerFileRecipe;
use DlangDockerized\Ddct\Datatype\ContainerImage;
use DlangDockerized\Ddct\Datatype\ContainerTag;
use DlangDockerized\Ddct\Datatype\ContainerVersionTag;
use DlangDockerized\Ddct\Datatype\SemVer;
use Exception;

final class ContainerBuilder
{
    public function __construct(
        private readonly ContainerEngine $containerEngine,
        private readonly ContainerFileMap $map,
        private readonly Tagger $tagger,
    ) {
    }

    private function buildContainerImpl(ContainerFileRecipe $recipe, BaseImage $baseImage): ContainerBuilderStatus
    {
        $containerFilePath = ContainerFile::getContainerFileTargetPath($recipe->app, $recipe->version, $baseImage);
        $tag = ContainerTag::makeFromRecipe($recipe, $baseImage);
        $this->containerEngine->build($containerFilePath, $tag);

        return ContainerBuilderStatus::Built;
    }

    private function buildContainer(ContainerFileRecipe $recipe, BaseImage $baseImage): ContainerBuilderStatus
    {
        $semver = SemVer::parse($recipe->version);
        if ($semver === null) {
            throw new Exception(
                'Bad version `' . $recipe->version . '` in container recipe `' . $recipe->app . '`'
            );
        }

        $tagVer = ContainerVersionTag::fromSemVer($semver, $baseImage->alias);

        if ($this->hasBuiltExact($recipe->app, $tagVer)) {
            writeln('Skipping build of preexisting container `', $recipe->app, ':', $tagVer, '`.');
            return ContainerBuilderStatus::Preexists;
        }

        writeln('Building container `', $recipe->app, ':', $tagVer, '`.');
        $result = $this->buildContainerImpl($recipe, $baseImage);

        writeln('Updating tags.');
        $this->tagger->applyAll();

        return $result;
    }

    public function buildByRecipe(ContainerFileRecipe $recipe, BaseImage $baseImage): ContainerBuilderStatus
    {
        foreach ($recipe->dependencies as $dependency) {
            $this->buildByKey($dependency, $baseImage, true);
        }

        return $this->buildContainer($recipe, $baseImage);
    }

    public function buildByKey(string $key, BaseImage $baseImage, bool $isDependency = false): ContainerBuilderStatus
    {
        $recipe = $this->map->getByKey($key);
        if ($recipe === null) {
            throw ($isDependency)
                ? new Exception('No recipe found for dependency `' . $key . '`.')
                : new Exception('No recipe found for requested container `' . $key . '`.');
        }

        return $this->buildByRecipe($recipe, $baseImage);
    }

    public function build(string $app, SemVer $version, BaseImage $baseImage): ContainerBuilderStatus
    {
        $recipe = $this->map->get($app, $version);
        if ($recipe === null) {
            throw new Exception('No recipe found for requested container `' . $app . '`:`' . $version . '`.');
        }

        return $this->buildByRecipe($recipe, $baseImage);
    }

    public function hasBuilt(string $app, ContainerVersionTag $version): ?ContainerImage
    {
        foreach ($this->containerEngine->listImages() as $image) {
            if ($image->getName() !== $app) {
                continue;
            }

            $imageVersion = $image->parseVersionTag();
            if (
                ($imageVersion === null)
                || !$imageVersion->isFullVersionNumber()
            ) {
                continue;
            }

            if (ContainerVersionTag::match($imageVersion, $version)) {
                return $image;
            }
        }

        return null;
    }

    public function hasBuiltExact(string $app, ContainerVersionTag $version): ?ContainerImage
    {
        foreach ($this->containerEngine->listImages() as $image) {
            if ($image->getName() !== $app) {
                continue;
            }

            $imageVersion = $image->parseVersionTag();
            if ($imageVersion === null) {
                continue;
            }

            if (
                ($imageVersion->major !== $version->major)
                || ($imageVersion->minor !== $version->minor)
                || ($imageVersion->patch !== $version->patch)
                || ($imageVersion->preRelease !== $version->preRelease)
                || ($imageVersion->baseImageAlias !== $version->baseImageAlias)
            ) {
                continue;
            }

            return $image;
        }

        return null;
    }
}
