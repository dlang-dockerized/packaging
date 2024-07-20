<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

final class ContainerImageTriplet
{
    public function __construct(
        public readonly string $app,
        public VersionSpecifier $version,
        public BaseImage $baseImage,
    ) {
    }

    public function __toString(): string
    {
        return $this->app . ':' . $this->version . '-' . $this->baseImage->alias;
    }
}
