<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

use Exception;
use LogicException;

final class TemplateExecutionErrorHandlers
{
    public const fileEndingCompiledTemplate = '.compiled-tpl.php';

    private array $templateStack = [];

    public function __construct(
        private string $templateEnginePath,
    ) {
    }

    public function getStack(): array {
        return array_reverse($this->templateStack);
    }

    public function push(string $templateName): void
    {
        $fileEnding = self::fileEndingCompiledTemplate;
        set_error_handler(function ($errno, $errstr, $errfile, $errline) use ($templateName, $fileEnding) {
            // Ignore errors caused somewhere else.
            if (!str_starts_with($errfile, $this->templateEnginePath)
                || !str_contains($errfile, ' : eval()\'d code')
            ) {
                return false;
            }

            throw new Exception(
                "Template execution error (code {$errno})"
                . " in `{$templateName}{$fileEnding}`({$errline}): {$errstr}"
            );
        }, E_ALL);

        array_push($this->templateStack, "{$templateName}{$fileEnding}");
    }

    public function pop(): void
    {
        restore_error_handler();
        $popped = array_pop($this->templateStack);
        if ($popped === null) {
            throw new LogicException('No error handlers to pop.');
        }
    }

    public function resetAndCheck(): void
    {
        if (count($this->templateStack) !== 0) {
            throw new LogicException('Popped less error handlers than pushed.');
        }
    }
}
