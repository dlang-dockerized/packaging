<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

use Exception;

final class ContainerFileRecipe
{
    public function __construct(
        public readonly string $app,
        public readonly string $version,
        public readonly string $template,
        public readonly array $env,
        public readonly array $dependencies,
    ) {
    }

    public static function fromAA(array $aa, string $appName, string $appVersion): self
    {
        $data = new AAWrapper($aa);
        $key = $appName . ':' . $appVersion;

        $tpl = $data->get('template');
        $env = $data->get('env');
        $dep = $data->get('dependencies');

        if ($env === null) {
            $env = [];
        }

        if ($dep === null) {
            $dep = [];
        }

        // Convention instead of configuration?
        if ($tpl === null) {
            $tpl = "{$appName}/{$appName}-image.containerfile";
        }

        if (!is_string($tpl)) {
            throw new Exception(
                'Cannot process recipe for Containerfile `'
                . $key
                . '` because of invalid `template` string.'
            );
        }

        if (!is_array($env)) {
            throw new Exception(
                'Cannot process recipe for Containerfile `'
                . $key
                . '` because of invalid `env` array.'
            );
        }

        if (!is_array($dep)) {
            throw new Exception(
                'Cannot process recipe for Containerfile `'
                . $key
                . '` because of invalid `dependencies` array.'
            );
        }

        return new ContainerFileRecipe(
            $appName,
            $appVersion,
            $tpl,
            $env,
            $dep,
        );
    }
}
