<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

enum ContainerBuilderStatus
{
    case Built;
    case Preexists;
}
