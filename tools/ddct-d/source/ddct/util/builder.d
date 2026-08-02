module ddct.util.builder;

import std.string;
import std.algorithm;
import std.file;
import std.exception;
import std.stdio;

import ddct.datatype;
import ddct.util.engine;
import ddct.util.containerfile;
import ddct.util.tagger;

@safe:

enum ContainerBuilderStatus {
    Built,
    Preexists
}

struct ContainerImageTriplet {
    string app;
    VersionSpecifier version_;
    BaseImage baseImage;

    string toString() const @safe {
        auto tag = ContainerVersionTag(version_, baseImage.alias);
        return app ~ ":" ~ tag.toString();
    }
}

struct UserAppBuildSelection {
    string appName;
    int versions;
    string[] add;
}

struct UserBuildSelection {
    string[] baseImageAliases;
    UserAppBuildSelection[] appSelections;

    static UserBuildSelection loadFromFile(string filePath) @safe {
        import ddct.datatype : parseIniFile, IniSection;
        auto ini = parseIniFile(filePath);

        string[] baseImageAliases;
        auto pBase = "__base_images" in ini;
        if (pBase !is null) {
            baseImageAliases = pBase.add;
        }

        if (baseImageAliases.length == 0) {
            throw new Exception("No base images listed in selection file `" ~ filePath ~ "`.");
        }

        UserAppBuildSelection[] appSelections;
        foreach (section, secData; ini) {
            if (section == "__base_images") continue;

            int versions = 0;
            auto pVers = "versions" in secData.simpleKeys;
            if (pVers !is null) {
                import std.conv : to;
                try {
                    versions = pVers.to!int;
                } catch (Exception) {
                    throw new Exception("Value of `versions` in section `" ~ section ~ "` is not an integer in selection file `" ~ filePath ~ "`.");
                }
            }

            appSelections ~= UserAppBuildSelection(section, versions, secData.add);
        }

        return UserBuildSelection(baseImageAliases, appSelections);
    }
}

class BuildSelector {
    private ContainerFileMap map;

    this(ContainerFileMap map) {
        this.map = map;
    }

    ContainerImageTriplet[] determineSelection(UserBuildSelection collection) @safe {
        BaseImage[] baseImages;
        foreach (alias_; collection.baseImageAliases) {
            baseImages ~= BaseImage.resolve(alias_);
        }

        ContainerImageTriplet[] result;
        foreach (appSel; collection.appSelections) {
            determineVersions(appSel, (appName, ver) {
                foreach (baseImage; baseImages) {
                    result ~= ContainerImageTriplet(appName, ver, baseImage);
                }
            });
            determineAdds(appSel, (appName, ver) {
                foreach (baseImage; baseImages) {
                    result ~= ContainerImageTriplet(appName, ver, baseImage);
                }
            });
        }
        return result;
    }

    private void determineVersions(UserAppBuildSelection appSelection, void delegate(string, VersionSpecifier) @safe receiver) @safe {
        if (appSelection.versions == 0) return;

        auto appVersionList = map.getAllByName(appSelection.appName);
        if (appVersionList is null) {
            throw new Exception("Selected app `" ~ appSelection.appName ~ "` not found.");
        }

        int counter = 0;
        foreach (semanticTag; appVersionList.semanticTags) {
            receiver(appSelection.appName, semanticTag.versionSpecifier);
            counter++;
            if (counter >= appSelection.versions) {
                break;
            }
        }
    }

    private void determineAdds(UserAppBuildSelection appSelection, void delegate(string, VersionSpecifier) @safe receiver) @safe {
        foreach (version_; appSelection.add) {
            auto versionSpecifier = VersionSpecifier.parse(version_);
            auto recipe = map.get(appSelection.appName, versionSpecifier);
            if (recipe is null) {
                throw new Exception("Selected recipe `" ~ appSelection.appName ~ "`:`" ~ version_ ~ "` not found.");
            }
            receiver(appSelection.appName, VersionSpecifier.parse(recipe.version_));
        }
    }
}

class ContainerBuilder {
    private ContainerEngine containerEngine;
    private ContainerFileMap map;
    private Tagger tagger;
    private bool autoPruneImages;

    this(ContainerEngine engine, ContainerFileMap map, Tagger tagger) {
        this.containerEngine = engine;
        this.map = map;
        this.tagger = tagger;
        this.autoPruneImages = determineAutoPruneImages();
    }

    private ContainerBuilderStatus buildContainerImpl(ContainerFileRecipe recipe, BaseImage baseImage) @safe {
        string containerFilePath = ContainerFile.getContainerFileTargetPath(recipe.app, recipe.version_, baseImage);

        auto version_ = VersionSpecifier.parse(recipe.version_);
        auto tagVer = ContainerVersionTag(version_, baseImage.alias);
        string tag = PackagerInfo.getContainerNamespace() ~ "/" ~ recipe.app ~ ":" ~ tagVer.toString(true);

        containerEngine.build(containerFilePath, tag);
        return ContainerBuilderStatus.Built;
    }

    private ContainerBuilderStatus buildContainer(ContainerFileRecipe recipe, BaseImage baseImage) @safe {
        auto version_ = VersionSpecifier.parse(recipe.version_);
        if (version_.isNull()) {
            throw new Exception("Bad version `" ~ recipe.version_ ~ "` in container recipe `" ~ recipe.app ~ "`");
        }

        auto tagVer = ContainerVersionTag(version_, baseImage.alias);

        if (hasBuiltExact(recipe.app, tagVer) !is null) {
            writeln("Skipping build of preexisting container `", recipe.app, ":", tagVer.toString(true), "`.");
            return ContainerBuilderStatus.Preexists;
        }

        writeln("Building container `", recipe.app, ":", tagVer.toString(true), "`.");
        writeln("--> Generating Containerfile.");
        string savedAs = ContainerFile.generateFile(recipe.app, recipe.version_, baseImage.alias);
        writeln("--> `", savedAs, "`");

        writeln("--> Building image.");
        auto result = buildContainerImpl(recipe, baseImage);

        writeln("--> Updating tags.");
        tagger.applyAll();

        pruneImagesIfEnabled();

        return result;
    }

    ContainerBuilderStatus buildByRecipe(ContainerFileRecipe recipe, BaseImage baseImage) @safe {
        foreach (dependency; recipe.dependencies) {
            buildByKey(dependency, baseImage, true);
        }
        return buildContainer(recipe, baseImage);
    }

    ContainerBuilderStatus buildByKey(string key, BaseImage baseImage, bool isDependency = false) @safe {
        auto recipe = map.getByKey(key);
        if (recipe is null) {
            throw isDependency
                ? new Exception("No recipe found for dependency `" ~ key ~ "`.")
                : new Exception("No recipe found for requested container `" ~ key ~ "`.");
        }
        return buildByRecipe(*recipe, baseImage);
    }

    ContainerBuilderStatus build(string app, VersionSpecifier version_, BaseImage baseImage) @safe {
        auto recipe = map.get(app, version_);
        if (recipe is null) {
            throw new Exception("No recipe found for requested container `" ~ app ~ "`:`" ~ version_.toString() ~ "`.");
        }
        return buildByRecipe(*recipe, baseImage);
    }

    ContainerBuilderStatus buildByTriplet(ContainerImageTriplet triplet) @safe {
        return build(triplet.app, triplet.version_, triplet.baseImage);
    }

    ContainerImage* hasBuilt(string app, ContainerVersionTag versionTag) @safe {
        foreach (img; containerEngine.listImages()) {
            if (img.getName() != app) continue;
            auto imgVersion = img.parseVersionTag();
            if (imgVersion is null || !imgVersion.isFullVersionNumber()) continue;
            if (ContainerVersionTag.match(*imgVersion, versionTag)) {
                return new ContainerImage(img);
            }
        }
        return null;
    }

    ContainerImage* hasBuiltExact(string app, ContainerVersionTag versionTag) @safe {
        foreach (img; containerEngine.listImages()) {
            if (img.getName() != app) continue;
            auto imgVersion = img.parseVersionTag();
            if (imgVersion is null || !imgVersion.isFullVersionNumber()) continue;
            if (imgVersion.compareTo(versionTag) == 0) {
                return new ContainerImage(img);
            }
        }
        return null;
    }

    private void pruneImagesIfEnabled() @safe {
        if (!autoPruneImages) return;
        writeln("--> Pruning images.");
        containerEngine.pruneImages();
    }

    private static bool determineAutoPruneImages() @trusted {
        import std.process : environment;
        string val = environment.get("AUTO_PRUNE_IMAGES");
        if (val.length == 0) return false;
        try {
            import std.string : toLower;
            if (val.toLower() == "true" || val == "1") return true;
            return false;
        } catch (Exception) {
            return false;
        }
    }
}
