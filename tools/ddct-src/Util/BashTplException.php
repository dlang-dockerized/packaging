<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

use Exception;

final class BashTplException extends Exception
{
    public readonly string $details;

    public function __construct(string $message, string $details)
    {
        parent::__construct($message);
        $this->details = $details;
    }
}
