<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

use DlangDockerized\Ddct\Path;
use Exception;

final class BashTpl
{
    private function __construct()
    {
    }

    public static function compile(string $templatePath): string
    {
        $env = [
            'BASH_TPL_TAG_DELIMS' => '{{ }}',
        ];

        $handle = proc_open(
            [
                Path::bashTplApp,
                $templatePath,
            ],
            [
                0 => ['pipe', 'r'],
                1 => ['pipe', 'w'],
                2 => ['pipe', 'w'],
            ],
            $pipes,
            null,
            $env,
        );

        if ($handle === false) {
            throw new Exception('Execution of command `' . Path::bashTplApp . '` failed.');
        }

        fclose($pipes[0]);

        $out = stream_get_contents($pipes[1]);
        $err = stream_get_contents($pipes[2]);

        $status = proc_close($handle);

        if ($status !== 0) {
            throw new BashTplException(
                "Compilation of template `{$templatePath}` failed.",
                $err,
            );
        }

        return $out;
    }

    public static function executeToFile(string $compiledTemplate, array $variables, string $outputFile): void
    {
        $handle = proc_open(
            'bash',
            [
                0 => ['pipe', 'r'],
                1 => ['file', $outputFile, 'w'],
                2 => ['pipe', 'w'],
            ],
            $pipes,
            null,
            $variables,
        );

        if ($handle === false) {
            throw new Exception('Template execution with `bash` failed.');
        }

        fwrite($pipes[0], $compiledTemplate);
        fclose($pipes[0]);
        $err = stream_get_contents($pipes[2]);

        $status = proc_close($handle);
        if ($status !== 0) {
            throw new BashTplException('Generation of file `' . $outputFile . '` from template failed.', $err);
        }
    }

}
