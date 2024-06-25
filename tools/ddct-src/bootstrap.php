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
// (This code is here at the end in order to resolve issues caused by limitations of “early binding”.)
$app = new \DlangDockerized\Ddct\App();
$exitCode = $app->run($argc, $argv);
exit($exitCode);
