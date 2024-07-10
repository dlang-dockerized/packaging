<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

use DlangDockerized\Ddct\Datatype\ContainerImage;
use DlangDockerized\Ddct\Datatype\ContainerTag;
use Exception;

class ContainerEngine
{
    private string $containerEngine;

    public function __construct(string $containerEngine = null)
    {
        if ($containerEngine === null) {
            $containerEngine = self::detectContainerEngine();
            if ($containerEngine === null) {
                throw new Exception('No `CONTAINER_ENGINE` specified. Auto-detection failed.');
            }
        }

        $this->containerEngine = $containerEngine;
    }

    public function getContainerEngine(): string
    {
        return $this->containerEngine;
    }

    private function jsonEncodeCmdArgs(mixed $data): string
    {
        return json_encode($data, JSON_PARTIAL_OUTPUT_ON_ERROR | JSON_UNESCAPED_SLASHES);
    }

    private function executeCommand(string ...$args): array
    {
        $cmd = [
            $this->containerEngine,
            ...$args
        ];

        $handle = proc_open(
            $cmd,
            [
                0 => ['pipe', 'r'],
                1 => ['pipe', 'w'],
                2 => ['pipe', 'w'],
            ],
            $pipes,
        );

        if ($handle === false) {
            throw new Exception(
                'Could not execute container management engine command `' . self::jsonEncodeCmdArgs($cmd) . '`.'
            );
        }

        fclose($pipes[0]);

        $out = [];
        while (true) {
            $line = stream_get_line($pipes[1], PHP_INT_MAX, "\n");
            if ($line === false) {
                break;
            }

            $out[] = $line;
        }

        $err = stream_get_contents($pipes[2]);

        fclose($pipes[1]);
        fclose($pipes[2]);

        $status = proc_close($handle);
        if ($status !== 0) {
            throw new Exception(
                'Command `' . self::jsonEncodeCmdArgs($cmd)
                . '` failed with status `' . $status . '`: '
                . rtrim($err)
            );
        }

        return $out;
    }

    private function passthruCommand(string ...$args): void
    {
        $cmd = [
            $this->containerEngine,
            ...$args
        ];

        $handle = proc_open(
            $cmd,
            [
                0 => STDIN,
                1 => STDOUT,
                2 => STDERR,
            ],
            $pipes,
        );

        if ($handle === false) {
            throw new Exception(
                'Could not execute container management engine command `' . self::jsonEncodeCmdArgs($cmd) . '`.'
            );
        }

        $status = proc_close($handle);
        if ($status !== 0) {
            throw new Exception(
                'Command `' . self::jsonEncodeCmdArgs($cmd) . '` failed with status `' . $status . '`.'
            );
        }
    }

    public function build(string $containerfilePath, ?ContainerTag $tag): void
    {
        $args = ['build', '-f', $containerfilePath, '.'];
        if ($tag !== null) {
            $args[] = '--tag';
            $args[] = (string)$tag;
        }

        $this->passthruCommand(...$args);
    }

    /**
     * @return ContainerImage[]
     */
    public function listImages(): array
    {
        $result = $this->executeCommand('images', '--format=json');

        return array_map(function (string $json) {
            $data = json_decode($json, true, JSON_THROW_ON_ERROR);
            return ContainerImage::fromAA($data);
        }, $result);
    }

    public function tagImage(string $sourceImage, string $tag): void
    {
        $this->passthruCommand('tag', $sourceImage, $tag);
    }

    public function removeImages(bool $force, string ...$images): void
    {
        if (count($images) === 0) {
            return;
        }

        if ($force) {
            $this->passthruCommand('rmi', '--force', ...$images);
        } else {
            $this->passthruCommand('rmi', ...$images);
        }
    }

    public static function detectContainerEngine(): ?string
    {
        if (isset($_SERVER['CONTAINER_ENGINE'])) {
            $containerEngine = $_SERVER['CONTAINER_ENGINE'];
            if (!self::hasApplication($containerEngine)) {
                throw new Exception(
                    'The requested `CONTAINER_ENGINE` (`' . $containerEngine . '`) is not available.'
                );
            }

            return $containerEngine;
        }
        if (self::hasDocker()) {
            return 'docker';
        }
        if (self::hasPodman()) {
            return 'podman';
        }

        return null;
    }

    private static function hasApplication(string $name): bool
    {
        $success = exec('command -v ' . escapeshellarg($name), result_code: $status);
        return (($success !== false) && ($status === 0));
    }

    public static function hasDocker(): bool
    {
        return self::hasApplication('docker');
    }

    public static function hasPodman(): bool
    {
        return self::hasApplication('podman');
    }
}
