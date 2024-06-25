<?php

declare(strict_types=1);

function write(...$args): void
{
    foreach ($args as $arg) {
        fwrite(STDERR, (string)$arg);
    }
}

function writeln(...$args): void
{
    write(...[...$args, PHP_EOL]);
}

function errorln(...$args): void
{
    writeln('Error: ', ...$args);
}

function usageln(string $argv0, string $args)
{
    writeln('Usage:', PHP_EOL, "\t", $argv0, '  ', $args);
}
