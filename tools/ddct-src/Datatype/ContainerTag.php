<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

use DlangDockerized\Ddct\Util\PackagerInfo;

final class ContainerTag
{
    private function __construct(
        public readonly string $containerNamespace,
        public readonly string $appName,
        public readonly string $appVersion,
        public readonly string $baseImageAlias,
    ) {
    }

    public function __toString(): string
    {
        return
            $this->containerNamespace
            . '/' . $this->appName
            . ':' . $this->appVersion
            . '-' . $this->baseImageAlias;
    }

    public static function makeFromRecipe(
        ContainerFileRecipe $recipe,
        BaseImage $baseImage,
    ): self {
        return new self(
            PackagerInfo::getContainerNamespace(),
            $recipe->app,
            $recipe->version,
            $baseImage->alias,
        );
    }
}
