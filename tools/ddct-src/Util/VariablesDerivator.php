<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

use DlangDockerized\Ddct\Datatype\BaseImage;
use DlangDockerized\Ddct\Datatype\Versioning;
use DlangDockerized\Ddct\Datatype\VersionSpecifier;

final class VariablesDerivator
{
    public function __construct(
        private string $appName,
        private VersionSpecifier $version,
        private BaseImage $baseImage,
    ) {
    }

    public function applyVariables(callable $receiver): void
    {
        $receiver('app_name', $this->appName);

        $receiver('base_image', $this->baseImage->image);
        $receiver('BASE_IMAGE', $this->baseImage->image);
        $receiver('base_image_alias', $this->baseImage->alias);
        $receiver('BASE_IMAGE_ALIAS', $this->baseImage->alias);

        if ($this->version->isCommit()) {
            $receiver('commit', $this->version->semanticTag);
            $receiver('version_string', (string)$this->version);
        }
        if ($this->version->isBranch()) {
            $receiver('branch', $this->version->semanticTag);
            $receiver('version_string', (string)$this->version);
        }

        if ($this->version->isSemantic()) {
            $receiver('semver', $this->version->semanticTag);
            $versionString = match ($this->determineVersionNumberScheme()) {
                Versioning::Semantic => $this->version->semanticTag->toString(),
                Versioning::Dm => $this->version->semanticTag->toDmString(),
            };

            $receiver('version_string', $versionString);
        }
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
