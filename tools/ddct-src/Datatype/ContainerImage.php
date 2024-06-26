<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

final class ContainerImage
{
    private ?string $repoNamespace = null;
    private ?string $repoName = null;

    public function __construct(
        public readonly ?string $id,
        public readonly ?string $repository,
        public readonly ?string $tag,
    ) {
    }

    private function parseRepository(): void
    {
        if ($this->repository === null) {
            $this->repoNamespace = '';
            $this->repoName = '';
            return;
        }

        $idxSep = strpos($this->repository, '/');
        if ($idxSep === false) {
            $this->repoNamespace = '';
            $this->repoName = '';
            return;
        }

        $this->repoNamespace = substr($this->repository, 0, $idxSep);
        $this->repoName = substr($this->repository, $idxSep + 1);
    }

    public function getNamespace(): string
    {
        if ($this->repoNamespace === null) {
            $this->parseRepository();
        }

        return $this->repoNamespace;
    }

    public function getName(): string
    {
        if ($this->repoName === null) {
            $this->parseRepository();
        }

        return $this->repoName;
    }

    public static function fromAA(array $aa): self
    {
        return new self(
            $aa['ID'] ?? null,
            $aa['Repository'] ?? null,
            $aa['Tag'] ?? null,
        );
    }
}
