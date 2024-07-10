<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

use DlangDockerized\Ddct\Datatype\AAWrapper;
use DlangDockerized\Ddct\Datatype\ContainerImage;
use DlangDockerized\Ddct\Datatype\ContainerVersionTag;

class Tagger
{
    public function __construct(
        private ContainerEngine $containerEngine,
    ) {
    }

    public function applyAll(): void
    {
        $tags = $this->determineTags();
        $this->applyTags($tags);
    }

    public function applyTags(array $tags): void
    {
        foreach ($tags as $source => $targets) {
            foreach ($targets as $tag) {
                $this->containerEngine->tagImage($source, $tag);
            }
        }
    }

    public function determineTags(): array
    {
        $images = $this->containerEngine->listImages();
        return $this->determineTagsForImages($images);
    }

    private static function determineTagsForTree(array $tree): array
    {
        $tagMapBuilder = new TagMapBuilder();

        foreach ($tree as $repo => $versionList) {
            $tagMapBuilder->nextRepository($repo);
            foreach ($versionList as $version) {
                $tagMapBuilder->add($version);
            }
        }

        return $tagMapBuilder->getData();
    }

    /**
     * @param ContainerImage[] $images
     */
    public static function determineTagsTreeForImages(array $images): array
    {
        $tree = new AAWrapper([]);

        foreach ($images as $image) {
            if (!$image->isOurs() || ($image->tag === null)) {
                continue;
            }

            $version = ContainerVersionTag::parse($image->tag);
            if (($version === null) || ($version->baseImageAlias === null)) {
                continue;
            }

            $tree->push($image->repository, $version);
        }

        $tree = $tree->getArray();
        foreach ($tree as &$appVersionList) {
            usort($appVersionList, function (ContainerVersionTag $a, ContainerVersionTag $b) {
                return $b->compareTo($a);
            });
        }
        unset($appVersionList);

        return $tree;
    }

    public static function determineTagsForImages(array $images): array
    {
        $tree = self::determineTagsTreeForImages($images);
        return self::determineTagsForTree($tree);
    }
}
