<?php

declare(strict_types=1);

namespace DlangDockerized\Ddct\Datatype;

use Exception;

final class UserBuildSelection
{
    /**
     * @param string[] $baseImageAliases
     * @param UserAppBuildSelection[] $apps
     */
    public function __construct(
        public readonly array $baseImageAliases,
        public readonly array $appSelections,
    ) {
    }

    public static function loadFromFile(string $filePath): self
    {
        $ini = IniLoader::load($filePath);

        $baseImageAliases = [];
        if (isset($ini['__base_images']) && isset($ini['__base_images']['add'])) {
            if (!is_array($ini['__base_images']['add'])) {
                throw new Exception('Bad `add` array in `__base_images` section of file `' . $filePath . '`.');
            }

            $baseImageAliases = $ini['__base_images']['add'];
        }

        if (count($baseImageAliases) < 0) {
            throw new Exception('No base images listed in selection file `' . $filePath . '`.');
        }
        unset($ini['__base_images']);

        $apps = [];
        foreach ($ini as $section => $data) {
            // determine requested versions count
            $versions = 0;
            if (isset($data['versions'])) {
                $versions = $data['versions'];
                if (!is_string($versions) || !ctype_digit($versions)) {
                    throw new Exception(
                        'Value of `versions` in section `' . $section . '` is not an integer'
                        . ' in selection file `' . $filePath . '`.'
                    );
                }
                $versions = (int)$versions;
            }

            $add = [];
            if (isset($data['add'])) {
                if (!is_array($data['add'])) {
                    throw new Exception(
                        'Bad `add` array in section `' . $section . '` of file `' . $filePath . '`.'
                    );
                }
                $add = $data['add'];
            }

            $apps[] = new UserAppBuildSelection($section, $versions, $add);
        }

        return new self(
            $baseImageAliases,
            $apps,
        );
    }
}
