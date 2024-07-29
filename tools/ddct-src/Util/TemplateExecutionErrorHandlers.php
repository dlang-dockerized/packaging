<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

use Exception;
use LogicException;

final class TemplateExecutionErrorHandlers
{
    public const fileEndingCompiledTemplate = '.compiled-tpl.php';

    private int $counter = 0;

    public function push(string $templateName): void
    {
        $fileEnding = self::fileEndingCompiledTemplate;
        set_error_handler(function ($errno, $errstr, $errfile, $errline) use ($templateName, $fileEnding) {
            throw new Exception(
                "Template execution error (code: {$errno})"
                . " in `{$templateName}{$fileEnding}`({$errline}): {$errstr}"
            );
        }, E_ALL);

        ++$this->counter;
    }

    public function pop(): void
    {
        restore_error_handler();
        --$this->counter;
    }

    public function resetAndCheck(): void
    {
        if ($this->counter !== 0) {
            throw new LogicException('Popped less error handlers than pushed.');
        }
    }
}
