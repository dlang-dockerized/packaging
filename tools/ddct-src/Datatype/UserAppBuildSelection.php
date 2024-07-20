<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

final class UserAppBuildSelection
{
    /**
     * @param string $add
     */
    public function __construct(
        public readonly string $appName,
        public readonly int $versions,
        public readonly array $add,
    ) {
    }
}
