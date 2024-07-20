<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Util;

use DlangDockerized\Ddct\Datatype\BaseImage;
use DlangDockerized\Ddct\Datatype\ContainerImageTriplet;
use DlangDockerized\Ddct\Datatype\UserAppBuildSelection;
use DlangDockerized\Ddct\Datatype\ContainerFileMap;
use DlangDockerized\Ddct\Datatype\UserBuildSelection;
use DlangDockerized\Ddct\Datatype\VersionSpecifier;
use Exception;

final class BuildSelector
{
    public function __construct(
        private ContainerFileMap $map,
    ) {
    }


    /**
     * @return ContainerImageTriplet[]
     */
    public function determineSelection(UserBuildSelection $collection): array
    {
        $baseImages = [];
        foreach ($collection->baseImageAliases as $baseImageAlias) {
            $baseImages[] = BaseImage::resolve($baseImageAlias);
        }

        $result = [];

        $this->determineSelectionNoBaseImage(
            $collection->appSelections,
            function (string $name, VersionSpecifier $version) use ($baseImages, &$result) {
                foreach ($baseImages as $baseImage) {
                    $result[] = new ContainerImageTriplet($name, $version, $baseImage);
                }
            }
        );

        return $result;
    }

    /**
     * @param UserAppBuildSelection[] $userBuildSelections
     */
    private function determineSelectionNoBaseImage(array $userBuildSelections, callable $receiver): void
    {
        foreach ($userBuildSelections as $appSelection) {
            $this->determineSelectionOfAppNoBaseImage($appSelection, $receiver);
        }
    }

    private function determineSelectionOfAppNoBaseImage(UserAppBuildSelection $appSelection, callable $receiver): void
    {
        $this->determineVersions($appSelection, $receiver);
        $this->determineAdds($appSelection, $receiver);
    }

    private function determineVersions(UserAppBuildSelection $appSelection, callable $receiver): void
    {
        // Early-exit possible?
        if ($appSelection->versions === 0) {
            return;
        }

        $appVersionList = $this->map->getAllByName($appSelection->appName);
        if ($appVersionList === null) {
            throw new Exception('Selected app `' . $appSelection->appName . '` not found.');
        }

        $counter = 0;
        foreach ($appVersionList->semanticTags as $semanticTag) {
            $receiver($appSelection->appName, $semanticTag->version);
            ++$counter;

            // Beyond requested version count?
            if ($counter === $appSelection->versions) {
                break;
            }
        }
    }

    private function determineAdds(UserAppBuildSelection $appSelection, callable $receiver): void
    {
        foreach ($appSelection->add as $version) {
            $versionSpecifier = VersionSpecifier::parse($version);
            $image = $this->map->get($appSelection->appName, $versionSpecifier);
            if ($image === null) {
                throw new Exception(
                    'Selected recipe `' . $appSelection->appName . '`:`' . $version . '` not found.'
                );
            }
            $receiver($appSelection->appName, VersionSpecifier::parse($image->version));
        }
    }
}
