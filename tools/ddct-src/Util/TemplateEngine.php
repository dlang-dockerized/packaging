<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

use Exception;

final class TemplateEngine
{
    private const tplOpenTag = '{{# ';
    private const tplPrintTag = '{{ ';
    private const tplCloseTag = ' }}';
    private const tplCloseTagLF = " }}\n";
    private const tplOpenEnd = '{{ end';
    private const phpOpenFull = '<?php ';
    private const tplIncludeTag = '{{< ';
    private const phpPrintTag = '<?= ';
    private const phpCloseTagLF = " ?>\n\n";
    private const phpCloseTag = " ?>\n";
    private const phpIncludeOpenTag = '<?php eval($_te->getCompiledTemplate(\'';
    private const phpIncludeCloseTag = '\'))?>';
    private const tab = "\t";

    private array $cache = [];

    public function __construct(
        private string $templatesDir,
    ) {
    }

    public function compile(string $templateName): void
    {
        $path = $this->makeTemplatePath($templateName);
        $f = fopen($path, 'r');
        if ($f === false) {
            throw new Exception('Unable to open template file `' . $path . '`.');
        }

        $result = '?>';

        $nestingLevel = 0;
        while (true) {
            $line = fgets($f);

            if ($line === false) {
                if (!feof($f)) {
                    throw new Exception('Error reading template file `' . $path . '`.');
                }
                break;
            }

            // trim indentation
            $nTabs = 0;
            foreach (str_split($line) as $char) {
                if ($char != self::tab) {
                    break;
                }
                ++$nTabs;
            }
            $indentationToTrim = min($nTabs, $nestingLevel);
            $line = substr($line, $indentationToTrim);

            $isFunction = str_starts_with($line, self::tplOpenTag);
            if ($isFunction) {
                $isEndingTag = str_starts_with($line, self::tplOpenEnd);

                if ($isEndingTag) {
                    --$nestingLevel;
                } else {
                    ++$nestingLevel;
                }

                $result .= self::phpOpenFull;
                $lineLength = strlen($line);
                // 8 = "{{# " . " }}\n"
                $line = substr($line, 4, ($lineLength - 8));
                unset($lineLength);
                $result .= $line;
                $result .= self::phpCloseTag;

                continue;
            }

            $isInclude = str_starts_with($line, self::tplIncludeTag);
            if ($isInclude) {
                $result .= self::phpIncludeOpenTag;
                $lineLength = strlen($line);
                // 8 = "{{< " . " }}\n"
                $line = substr($line, 4, ($lineLength - 8));
                unset($lineLength);
                $result .= $line;
                $result .= self::phpIncludeCloseTag;
                continue;
            }

            // variables
            $line = str_replace(self::tplPrintTag, self::phpPrintTag, $line);
            $line = str_replace(self::tplCloseTagLF, self::phpCloseTagLF, $line);
            $line = str_replace(self::tplCloseTag, self::phpCloseTag, $line);
            $result .= $line;
        }

        fclose($f);

        $this->cache[$templateName] = $result;
    }

    public function compileIfNotInCache(string $templateName): void
    {
        if (isset($this->cache[$templateName])) {
            return;
        }

        $this->compile($templateName);
    }

    public function getCompiledTemplate(string $templateName): string
    {
        $this->compileIfNotInCache($templateName);
        return $this->cache[$templateName];
    }

    public function executeToFile(string $templateName, array $variables, string $outputFile): void
    {
        if (!ob_start()) {
            throw new Exception('Could not start output-buffering.');
        }

        try {
            $this->execute($templateName, $variables);

            $written = file_put_contents($outputFile, ob_get_contents(), LOCK_EX);
            if ($written === false) {
                throw new Exception('Failed to write template file.');
            }
        } finally {
            if (!ob_end_clean()) {
                throw new Exception('Could not end output-buffering.');
            }
        }
    }

    public function execute(string $templateName, array $variables): void
    {
        $this->executeTemplate(
            $templateName,
            $variables,
        );
    }

    private function executeTemplate(string $templateName, array $variables)
    {
        $this->compileIfNotInCache($templateName);

        (function (TemplateEngine $_te, string $_tplCode, array $_variables) {
            foreach ($_variables as $_name => $_value) {
                $$_name = $_value;
            }
            eval($_tplCode);
        })(
            $this,
            $this->cache[$templateName],
            $variables,
        );
    }

    private function makeTemplatePath(string $templateName): string
    {
        return $this->templatesDir . '/' . $templateName;
    }
}
