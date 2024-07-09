# Conventions

## Variables

| Origin | Case |
| :-- | :--|
| Variable Derivator/Template Engine (DDCT) | `snake_case` (lowercase) |
| Containerfile definition (`containerfiles.ini`) | `SNAKE_CASE` (uppercase) |
| Embedded code (in template) | `camelCase` |

## Debugging

For debug purposes, one can save the compiled templates to disk
by setting environment variable `TPL_DEBUG` to `file`.

Usage:
`TPL_DEBUG=file ./ddct generate…`

The compiled templates are saved to `<template-file>.compiled-tpl.php`.

On systems with GNU find (or similar programs) installed, such debug files can
be conveniently deleted by running `find . -name '*.compiled-tpl.php' -delete`
from within the repository root or templates directory.
