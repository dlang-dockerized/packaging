<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

use DlangDockerized\Ddct\Util\PackagerInfo;

final class ContainerTag
{
    private function __construct(
        public readonly string $containerNamespace,
        public readonly string $appName,
        public readonly ContainerVersionTag $version,
    ) {
    }

    public function __toString(): string
    {
        return
            $this->containerNamespace
            . '/' . $this->appName
            . ':' . $this->version;
    }

    public static function makeFromRecipe(
        ContainerFileRecipe $recipe,
        BaseImage $baseImage,
    ): self {
        $semver = SemVer::parse($recipe->version);
        return new self(
            PackagerInfo::getContainerNamespace(),
            $recipe->app,
            ContainerVersionTag::fromSemVer($semver, $baseImage->alias),
        );
    }
}
