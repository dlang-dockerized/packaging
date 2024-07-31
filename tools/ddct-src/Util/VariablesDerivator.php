<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

use DlangDockerized\Ddct\Datatype\BaseImage;
use DlangDockerized\Ddct\Datatype\Versioning;
use DlangDockerized\Ddct\Datatype\VersionSpecifier;
use DlangDockerized\Ddct\Datatype\VersionSpecifierType;

final class VariablesDerivator
{
    public function __construct(
        private string $appName,
        private VersionSpecifier $version,
        private ?VersionSpecifier $languageLevel,
        private BaseImage $baseImage,
        private array $dependencies,
        private array $extras,
    ) {
    }

    public function applyVariables(callable $receiver): void
    {
        $receiver('container_namespace', PackagerInfo::getContainerNamespace());

        $receiver('app_name', $this->appName);

        $receiver('base_image', $this->baseImage->image);
        $receiver('base_image_alias', $this->baseImage->alias);

        $receiver('version', $this->version);

        switch ($this->version->type) {
            case VersionSpecifierType::Commit:
                $receiver('commit', $this->version->commit);
                $receiver('version_string', (string)$this->version);
                break;

            case VersionSpecifierType::Branch:
                $receiver('branch', $this->version->branch);
                $receiver('version_string', (string)$this->version);
                break;

            case VersionSpecifierType::SemanticTag:
                $receiver('semver', $this->version->semanticTag);
                $versionString = match ($this->determineVersionNumberScheme()) {
                    Versioning::Semantic => $this->version->semanticTag->toString(),
                    Versioning::Dm => $this->version->semanticTag->toDmString(),
                };
                $receiver('version_string', $versionString);
                break;
        }

        if ($this->languageLevel !== null) {
            $languageLevelString = ($this->languageLevel->type === VersionSpecifierType::SemanticTag)
                ? $this->languageLevel->semanticTag->toDmString()
                : (string)$this->languageLevel;
            $receiver('language_level', $this->languageLevel);
            $receiver('language_level_string', $languageLevelString);
        }

        $dependenciesAA = [];
        foreach ($this->dependencies as $dependency) {
            $parsed = ContainerFile::parseKey($dependency);
            if ($parsed === false) {
                continue;
            }

            $dependenciesAA[$parsed[0]] = $parsed[1];
        }
        $receiver('dependencies', $dependenciesAA);

        $extrasAA = [];
        foreach ($this->extras as $extra => $version) {
            $extrasAA[$extra] = VersionSpecifier::parse($version);
        }
        $receiver('extras', $extrasAA);
    }

    public function getVariables(): array
    {
        $result = [];
        $this->applyVariables(function (string $key, mixed $value) use (&$result): void {
            $result[$key] = $value;
        });
        return $result;
    }

    private function determineVersionNumberScheme(): Versioning
    {
        return match ($this->appName) {
            'dmd' => Versioning::Dm,
            default => Versioning::Semantic,
        };
    }
}
