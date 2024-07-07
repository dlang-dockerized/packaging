<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

use DlangDockerized\Ddct\Datatype\AAWrapper;
use DlangDockerized\Ddct\Datatype\BaseImage;
use DlangDockerized\Ddct\Datatype\ContainerVersionTag;
use DlangDockerized\Ddct\Datatype\SemVer;
use DlangDockerized\Ddct\Datatype\VersionSpecifierType;
use LogicException;

final class TagMapBuilder
{
    private readonly string $defaultBaseImageAlias;
    private AAWrapper $data;
    private ?string $repository = null;
    private int $previousMajor;
    private int $previousMinor;
    private bool $firstInRepository;

    public function __construct()
    {
        $this->defaultBaseImageAlias = BaseImage::resolve('default')->alias;
        $this->data = new AAWrapper();
    }

    public function getData(): array
    {
        return $this->data->getArray();
    }

    public function nextRepository(string $repository): void
    {
        $this->repository = $repository;
        $this->previousMajor = PHP_INT_MAX;
        $this->previousMinor = PHP_INT_MAX;
        $this->firstInRepository = true;
    }

    public function add(ContainerVersionTag $version): void
    {
        if ($this->repository === null) {
            throw new LogicException('`nextRepository()` must be called before `add()`.');
        }

        match ($version->versionSpecifier->type) {
            VersionSpecifierType::Null => throw new LogicException(
                'Cannot `add()` a `ContainerVersionTag` of type `Null`.'
            ),
            VersionSpecifierType::Branch, VersionSpecifierType::Commit => $this->addGeneric($version),
            VersionSpecifierType::SemanticTag => $this->addSemanticTag($version),
        };
    }

    public function addGeneric(ContainerVersionTag $version): void
    {
        $source = $this->repository . ':' . $version;
        $this->pushString($source, $version->baseImageAlias, (string)$version->versionSpecifier);
    }

    public function addSemanticTag(ContainerVersionTag $versionTag): void
    {
        $source = $this->repository . ':' . $versionTag;

        $version = $versionTag->versionSpecifier->semanticTag;

        if ($this->firstInRepository) {
            // Don't reserve wildcard-tags for pre-release versions.
            if ($version->preRelease === null) {
                $this->firstInRepository = false;
            }

            $this->pushString($source, $versionTag->baseImageAlias, 'latest');
        }

        if ($version->major < $this->previousMajor) {
            // Don't reserve wildcard-tags for pre-release versions.
            if ($version->preRelease === null) {
                $this->previousMajor = $version->major;
            }

            $this->previousMinor = PHP_INT_MAX;

            $this->pushSemanticTag($source, $versionTag->baseImageAlias, $version, 1);
        }

        if ($version->minor < $this->previousMinor) {
            $this->previousMinor = $version->minor;
            $this->pushSemanticTag($source, $versionTag->baseImageAlias, $version, 2);
        }

        $this->pushSemanticTag($source, $versionTag->baseImageAlias, $version, 3);
    }

    private function pushSemanticTag(string $source, string $baseImageAlias, SemVer $version, int $depth): void
    {
        $versionString = match ($depth) {
            1 => (string)$version->major,
            2 => $version->major . '.' . $version->minor,
            3 => (string )$version,
        };

        $this->pushString($source, $baseImageAlias, $versionString);
    }

    private function pushString(string $source, string $baseImageAlias, string $version): void
    {
        $tagShort = $this->repository . ':' . $version;
        $tagFull = $tagShort . '-' . $baseImageAlias;
        $this->data->push($source, $tagFull);

        $usesDefaultBaseImage = ($baseImageAlias === $this->defaultBaseImageAlias);
        if ($usesDefaultBaseImage) {
            $this->data->push($source, $tagShort);
        }
    }
}
