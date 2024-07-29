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
    private const tplOpenEnd = '{{# end';
    private const phpOpenFull = '<?php ';
    private const tplIncludeTag = '{{< ';
    private const phpPrintTag = '<?= ';
    private const phpCloseTagLF = " ?>\n\n";
    private const phpCloseTag = " ?>\n";
    private const phpIncludeOpenTag = '<?php $_eh->push(\'';
    private const phpIncludeMiddle = '\');eval($_te->getCompiledTemplate(\'';
    private const phpIncludeCloseTag = '\'));$_eh->pop()?>';
    private const tab = "\t";

    private array $cache = [];
    private TemplateExecutionErrorHandlers $errorHandlers;

    public function __construct(
        private string $templatesDir,
    ) {
        $this->errorHandlers = new TemplateExecutionErrorHandlers();
    }

    public function compile(string $templateName): void
    {
        $path = $this->makeTemplatePath($templateName);
        $f = fopen($path, 'r');
        if ($f === false) {
            throw new Exception('Unable to open template file `' . $path . '`.');
        }

        $result = '?>';

        $nesting = [];
        $lineNumber = 0;
        while (true) {
            ++$lineNumber;
            $nestingLevel = count($nesting);
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

            $lineTrimmed = ltrim($line);

            $isFunction = str_starts_with($lineTrimmed, self::tplOpenTag);
            if ($isFunction) {
                $isEndingTag = str_starts_with($lineTrimmed, self::tplOpenEnd);

                if ($isEndingTag) {
                    array_pop($nesting);
                } else {
                    if (end($nesting) !== $nTabs) {
                        $nesting[] = $nTabs;
                    }
                }

                if (!str_ends_with($lineTrimmed, self::tplCloseTagLF)) {
                    throw new Exception(
                        'Bad/missing template function closing tag `}}` in `'
                        . $templateName . '`:`' . $lineNumber . '`.'
                    );
                }

                $result .= self::phpOpenFull;
                $lineLength = strlen($lineTrimmed);
                // 8 = "{{# " . " }}\n"
                $line = substr($lineTrimmed, 4, ($lineLength - 8));
                unset($lineLength);
                $result .= $line;
                $result .= self::phpCloseTag;

                continue;
            }

            $isInclude = str_starts_with($lineTrimmed, self::tplIncludeTag);
            if ($isInclude) {
                $result .= self::phpIncludeOpenTag;
                $lineLength = strlen($line);
                // 8 = "{{< " . " }}\n"
                $line = substr($line, 4, ($lineLength - 8));
                unset($lineLength);
                $result .= $line;
                $result .= self::phpIncludeMiddle;
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

        // Shall write compiled template to file?
        if (isset($_SERVER['TPL_DEBUG']) && ($_SERVER['TPL_DEBUG'] === 'file')) {
            file_put_contents(
                $this->makeTemplatePath($templateName) . TemplateExecutionErrorHandlers::fileEndingCompiledTemplate,
                $this->cache[$templateName]
            );
        }
    }

    public function getCompiledTemplate(string $templateName): string
    {
        $this->compileIfNotInCache($templateName);
        return $this->cache[$templateName];
    }

    public function executeToFile(string $templateName, array $variables, string $outputFile): void
    {
        $this->compileIfNotInCache($templateName);

        if (!ob_start()) {
            throw new Exception('Could not start output-buffering.');
        }

        try {
            $this->executeTemplate($templateName, $variables);

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
        $this->compileIfNotInCache($templateName);
        $this->executeTemplate($templateName, $variables);
    }

    private function executeTemplate(string $templateName, array $variables)
    {
        $this->errorHandlers->push($templateName);

        (function (TemplateEngine $_te, TemplateExecutionErrorHandlers $_eh, string $_tplCode, array $_variables) {
            foreach ($_variables as $_name => $_value) {
                $$_name = $_value;
            }
            eval($_tplCode);
        })(
            $this,
            $this->errorHandlers,
            $this->cache[$templateName],
            $variables,
        );

        $this->errorHandlers->pop();
        $this->errorHandlers->resetAndCheck();
    }

    private function makeTemplatePath(string $templateName): string
    {
        return $this->templatesDir . '/' . $templateName;
    }
}
