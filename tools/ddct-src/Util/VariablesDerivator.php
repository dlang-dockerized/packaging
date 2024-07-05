<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

use DlangDockerized\Ddct\Datatype\BaseImage;
use DlangDockerized\Ddct\Datatype\SemVer;
use DlangDockerized\Ddct\Datatype\Versioning;

final class VariablesDerivator
{
    public function __construct(
        private string $appName,
        private SemVer $version,
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

        $receiver('version', $this->version);

        $versionString = match ($this->determineVersioning()) {
            Versioning::Semantic => $this->version->toString(),
            Versioning::Dm => $this->version->toDmString(),
        };
        $receiver('version_string', $versionString);
    }

    public function getVariables(): array
    {
        $result = [];
        $this->applyVariables(function (string $key, mixed $value) use (&$result): void {
            $result[$key] = $value;
        });
        return $result;
    }

    private function determineVersioning(): Versioning
    {
        return match ($this->appName) {
            'dmd' => Versioning::Dm,
            default => Versioning::Semantic,
        };
    }
}