<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

final class AppVersionAppList
{
    /**
     * @var AppVersionList[]
     */
    private array $data = [];

    public function __construct()
    {
    }

    public function push(string $appName, ContainerFileMapEntry $entry): void
    {
        if (!isset($this->data[$appName])) {
            $this->data[$appName] = new AppVersionList();
        }

        $this->data[$appName]->push($entry);
    }

    public function has(string $appName): bool
    {
        return isset($this->data[$appName]);
    }
    public function get(string $appName): ?AppVersionList
    {
        return $this->data[$appName] ?? null;
    }

    public function sort()
    {
        foreach($this->data as $appVersionList) {
            $appVersionList->sort();
        }
    }
}
