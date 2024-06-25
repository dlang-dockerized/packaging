<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

final class AAWrapper
{
    public function __construct(
        private array $data = [],
    ) {
    }

    public function getArray(): array
    {
        return $this->data;
    }

    public function get(mixed ...$keys): mixed
    {
        $data = $this->data;
        foreach ($keys as $key) {
            $data = $this->getImpl($data, $key);

            if ($data === null) {
                return null;
            }
        }

        return $data;
    }

    private static function getImpl(array $aa, mixed $key): mixed
    {
        if (!isset($aa[$key])) {
            return null;
        }

        return $aa[$key];
    }

    public function has(mixed ...$keys): bool
    {
        $data = &$this->data;
        foreach ($keys as $key) {
            if (!isset($data[$key])) {
                return false;
            }

            $data = &$data[$key];
        }

        return true;
    }

    public function push(mixed ...$keysAndValue): void
    {
        $count = count($keysAndValue);
        if ($count === 0) {
            return;
        }

        if ($count === 1) {
            $this->data[] = $keysAndValue[0];
        }

        $data = &$this->data;

        $idxValue = ($count - 1);
        $keys = array_slice($keysAndValue, 0, $idxValue);
        foreach ($keys as $key) {
            if (!isset($data[$key])) {
                $data[$key] = [];
            } elseif (!is_array($data[$key])) {
                $data[$key] = [$data[$key]];
            }

            $data = &$data[$key];
        }

        $data[] = $keysAndValue[$count - 1];
    }

    public function set(mixed ...$keysAndValue): void
    {
        $count = count($keysAndValue);
        if ($count === 0) {
            return;
        }

        if ($count === 1) {
            $this->data = $keysAndValue[0];
        }

        $data = &$this->data;

        $idxLastKey = ($count - 2);
        $idxValue = ($count - 1);
        $keys = array_slice($keysAndValue, 0, $idxLastKey);
        foreach ($keys as $key) {
            if (!isset($data[$key]) || !is_array($data[$key])) {
                $data[$key] = [];
            }

            $data = &$data[$key];
        }

        $data[$keysAndValue[$idxLastKey]] = $keysAndValue[$idxValue];
    }
}
