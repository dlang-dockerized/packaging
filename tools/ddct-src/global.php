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

function usageln(string $argv0, string $args): void
{
    writeln('Usage:', PHP_EOL, "\t", $argv0, '  ', $args);
}

function output(...$args): void
{
    foreach ($args as $arg) {
        fwrite(STDOUT, (string)$arg);
    }
}

function outputln(...$args): void
{
    output(...[...$args, PHP_EOL]);
}
