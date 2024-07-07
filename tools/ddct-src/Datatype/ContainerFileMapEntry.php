<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

final class ContainerFileMapEntry
{
    public function __construct(
        public readonly VersionSpecifier $version,
        public readonly ContainerFileRecipe $recipe,
    ) {
    }
}
