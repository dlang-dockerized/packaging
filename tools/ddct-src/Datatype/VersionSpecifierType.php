<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

enum VersionSpecifierType
{
    case Null;
    case Branch;
    case Commit;
    case SemanticTag;
}
