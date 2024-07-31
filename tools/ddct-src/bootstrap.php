<?php

declare(strict_types=1);

#######################################################################
# SPDX-License-Identifier: BSL-1.0
# Copyright (c) 2024 Elias Batek
#
# Distributed under the Boost Software License, Version 1.0.
#    (See accompanying file LICENSE_1_0.txt or copy at
#          https://www.boost.org/LICENSE_1_0.txt)
#######################################################################
# ddct: dlang-dockerized Container Toolkit
#######################################################################

if (version_compare(PHP_VERSION, '8.2', '<')) {
    fwrite(STDERR, 'Unsupported PHP interpreter; version ^8.2 required.' . PHP_EOL);
    exit(1);
}

spl_autoload_register(function (string $className) {
    if (!str_starts_with($className, 'DlangDockerized\\Ddct\\')) {
        return false;
    }

    $short = substr($className, 21);
    $path = __DIR__ . '/' . str_replace('\\', '/', $short) . '.php';

    if (!file_exists($path)) {
        return false;
    }

    require $path;
    return true;
});

require __DIR__ . '/global.php';

// App entry
$app = new \DlangDockerized\Ddct\App();
$exitCode = $app->run($argc, $argv);
exit($exitCode);
