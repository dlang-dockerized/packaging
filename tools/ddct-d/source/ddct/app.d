module ddct.app;

import std.stdio;
import std.string;
import std.algorithm;
import std.exception;
import std.conv;

import ddct.datatype;
import ddct.util.engine;
import ddct.util.containerfile;
import ddct.util.tagger;
import ddct.util.builder;
import ddct.path : Path;

@safe:

final class App {
    int run(string[] args) {
        try {
            return runCommand(args);
        } catch (Exception ex) {
            stderr.writeln("Error: ", ex.msg);
            return 1;
        }
    }

    private int runCommand(string[] args) {
        if (args.length < 2) {
            writeln("dlang-dockerized Container Toolkit");
            stderr.writeln("Error: No command provided.");
            usageln(args[0], "<command> [<args>...]");
            return 1;
        }

        string userCommand = args[1].toLower();

        switch (userCommand) {
            case "build":                    return build(args);
            case "build-selection":          return buildSelection(args);
            case "can-build":                return canBuild(args);
            case "detect-engine":            return detectEngine(args);
            case "detect-engine-arch":       return detectEngineArch(args);
            case "generate":                 return generate(args);
            case "generate-all":             return generateAll(args);
            case "has-built":                return hasBuilt(args);
            case "help", "--help":           return help(args);
            case "namespace-copy":           return namespaceCopy(args);
            case "namespace-echo":           return namespaceEcho(args);
            case "namespace-publish":        return namespacePublish(args);
            case "namespace-remove-all":     return namespaceRemoveAll(args);
            case "tag":                      return tag(args);
            default:
                stderr.writeln("Error: `", userCommand, "` is not a ddct command.");
                return 1;
        }
    }

    private void usageln(string argv0, string args) {
        writeln("Usage:\n\t", argv0, "  ", args);
    }

    private int help(string[] args) {
        if (args.length != 2) {
            stderr.writeln("Error: Too many arguments.");
            return 1;
        }

        writeln(
            "dlang-dockerized Container Toolkit\n\n",
            "Available commands:\n",
            "  build                   - Build a specific container image.\n",
            "  build-selection         - Build the defined selection of container images.\n",
            "  can-build               - Determine whether a container image is available for building.\n",
            "  detect-engine           - Detect which container management engine will be used.\n",
            "  generate-all            - Generate all Containerfiles from the templates.\n",
            "  generate                - Generate a specific Containerfile from the templates.\n",
            "  has-built               - Check whether a certain container image has been built and is available.\n",
            "  help                    - Print this help text.\n",
            "  namespace-copy          - Copy all images from the current namespace to another.\n",
            "  namespace-echo          - Print the current namespace.\n",
            "  namespace-publish       - Publish the current namespace to the registry.\n",
            "  namespace-remove-all    - Remove all container images from the current namespace (by tag).\n",
            "  tag                     - Update the tags of all container images within the current namespace.\n"
        );
        return 0;
    }

    private bool readArgsAppNameVersionBaseimage(
        string[] args,
        string command,
        ref string outAppName,
        ref string outAppVersion,
        ref string outBaseImageAlias
    ) {
        string usageArgs = command ~ " <app-name> <version> [<base-image>]";

        if (args.length < 4) {
            stderr.writeln("Error: No app-name specified.");
            usageln(args[0], usageArgs);
            return false;
        }
        outAppName = args[2];

        if (args.length < 5) {
            stderr.writeln("Error: No version specified for app `", outAppName, "`.");
            usageln(args[0], usageArgs);
            return false;
        }
        outAppVersion = args[3];

        outBaseImageAlias = (args.length >= 6) ? args[4] : "default";
        return true;
    }

    private int build(string[] args) {
        string appName, appVersion, baseImageAlias;
        if (!readArgsAppNameVersionBaseimage(args, "build", appName, appVersion, baseImageAlias)) {
            return 1;
        }

        auto map = ContainerFileMap.parseDefinitions(parseIniFile(Path.containerFileDefinitionsFile));
        auto version_ = VersionSpecifier.parse(appVersion, true);
        if (version_.isNull()) {
            stderr.writeln("Error: Cannot parse the specified version string `", appVersion, "`.");
            return 1;
        }

        auto baseImage = BaseImage.resolve(baseImageAlias);
        auto containerEngine = new ContainerEngine();
        auto tagger = new Tagger(containerEngine);
        auto containerBuilder = new ContainerBuilder(containerEngine, map, tagger);

        auto buildStatus = containerBuilder.build(appName, version_, baseImage);
        if (buildStatus == ContainerBuilderStatus.Preexists) {
            writeln("Nothing to do.");
        } else if (buildStatus == ContainerBuilderStatus.Built) {
            writeln("Done.");
        }
        return 0;
    }

    private int buildSelection(string[] args) {
        bool hasSelectionFilePath = (args.length == 3);
        if (!hasSelectionFilePath && args.length != 2) {
            stderr.writeln("Error: Too many arguments.");
            usageln(args[0], "build-selection [<selection.ini>]");
            return 1;
        }

        string selectionFilePath = hasSelectionFilePath
            ? args[2]
            : Path.definitionsDir ~ "/build-selection.ini";

        auto userBuildSelection = UserBuildSelection.loadFromFile(selectionFilePath);
        auto map = ContainerFileMap.parseDefinitions(parseIniFile(Path.containerFileDefinitionsFile));

        auto buildSelector = new BuildSelector(map);
        auto machineSelection = buildSelector.determineSelection(userBuildSelection);

        auto containerEngine = new ContainerEngine();
        auto tagger = new Tagger(containerEngine);
        auto containerBuilder = new ContainerBuilder(containerEngine, map, tagger);

        foreach (triplet; machineSelection) {
            writeln("Building image `", triplet.toString(), "` from selection.");
            auto buildStatus = containerBuilder.buildByTriplet(triplet);
            if (buildStatus == ContainerBuilderStatus.Preexists) {
                writeln("-> Nothing to do.");
            } else if (buildStatus == ContainerBuilderStatus.Built) {
                writeln("-> Done.");
            }
        }
        return 0;
    }

    private int canBuild(string[] args) {
        string appName, appVersion, baseImageAlias;
        if (!readArgsAppNameVersionBaseimage(args, "can-build", appName, appVersion, baseImageAlias)) {
            return 1;
        }

        auto map = ContainerFileMap.parseDefinitions(parseIniFile(Path.containerFileDefinitionsFile));
        auto version_ = VersionSpecifier.parse(appVersion, true);
        if (version_.isNull()) {
            stderr.writeln("Error: Cannot parse the specified version string `", appVersion, "`.");
            return 1;
        }

        auto recipe = map.get(appName, version_);
        if (recipe is null) {
            stderr.writeln("Error: No recipe found for requested container `", appName, "`:`", version_.toString(), "`");
            return 1;
        }

        writeln(recipe.app, ":", recipe.version_);
        return 0;
    }

    private int detectEngine(string[] args) {
        try {
            string detected = ContainerEngine.detectContainerEngine();
            if (detected.length == 0) return 1;
            writeln(detected);
            return 0;
        } catch (Exception) {
            return 1;
        }
    }

    private int detectEngineArch(string[] args) {
        auto containerEngine = new ContainerEngine();
        string arch = containerEngine.getArch();
        writeln(arch);
        return 0;
    }

    private int generate(string[] args) {
        string appName, appVersion, baseImageAlias;
        if (!readArgsAppNameVersionBaseimage(args, "generate", appName, appVersion, baseImageAlias)) {
            return 1;
        }

        string savedAs = ContainerFile.generateFile(appName, appVersion, baseImageAlias);
        writeln("Containerfile saved to `", savedAs, "`.");
        return 0;
    }

    private int generateAll(string[] args) {
        if (args.length > 3) {
            stderr.writeln("Error: Too many arguments.");
            usageln(args[0], "generate-all [<base-image>]");
            return 1;
        }

        string baseImageAlias = (args.length >= 3) ? args[2] : "default";
        auto containerDefs = parseIniFile(Path.containerFileDefinitionsFile);

        bool error = false;
        foreach (key, recipeRaw; containerDefs) {
            auto app = ContainerFile.parseKey(key);
            if (app.length != 2) {
                stderr.writeln("Error: Encountered invalid Containerfile recipe definition `", key, "`.");
                error = true;
                continue;
            }

            writeln("Generating Containerfile for `", key, "`.");
            string savedAs = ContainerFile.generateFile(app[0], app[1], baseImageAlias);
            writeln("Containerfile saved to `", savedAs, "`.");
        }

        return error ? 1 : 0;
    }

    private int hasBuilt(string[] args) {
        string appName, appVersion, baseImageAlias;
        if (!readArgsAppNameVersionBaseimage(args, "has-built", appName, appVersion, baseImageAlias)) {
            return 1;
        }

        auto map = ContainerFileMap.parseDefinitions(parseIniFile(Path.containerFileDefinitionsFile));
        auto version_ = VersionSpecifier.parse(appVersion, true);
        if (version_.isNull()) {
            stderr.writeln("Error: Cannot parse the specified version string `", appVersion, "`.");
            return 1;
        }

        auto baseImage = BaseImage.resolve(baseImageAlias);
        auto tagver = ContainerVersionTag(version_, baseImage.alias);

        auto containerEngine = new ContainerEngine();
        auto tagger = new Tagger(containerEngine);
        auto containerBuilder = new ContainerBuilder(containerEngine, map, tagger);
        auto image = containerBuilder.hasBuilt(appName, tagver);

        if (image is null) {
            return 1;
        }

        writeln(image.toString());
        return 0;
    }

    private int namespaceCopy(string[] args) {
        if (args.length != 3) {
            stderr.writeln("Error: Invalid number of arguments.");
            usageln(args[0], "namespace-copy <target-repo-namespace>");
            return 1;
        }

        string namespaceSource = PackagerInfo.getContainerNamespace();
        size_t namespaceSourceLength = namespaceSource.length;
        string namespaceTarget = args[2];

        auto containerEngine = new ContainerEngine();

        foreach (imageSource; containerEngine.listImages()) {
            if (imageSource.getNamespace() != namespaceSource) {
                continue;
            }

            string tagSource = imageSource.tag;
            if (tagSource.length == 0) {
                writeln("Warning: Skipping tag-less image entry `", imageSource.id, "`.");
                continue;
            }

            string repoSource = imageSource.repository;
            string repoTarget = namespaceTarget ~ repoSource[namespaceSourceLength .. $];

            string fullTagTarget = repoTarget ~ ":" ~ tagSource;
            string fullTagSource = imageSource.toString();

            writeln(fullTagTarget);
            containerEngine.tagImage(fullTagSource, fullTagTarget);
        }

        return 0;
    }

    private int namespaceEcho(string[] args) {
        if (args.length != 2) {
            stderr.writeln("Error: Command `namespace-echo` does not support any arguments.");
            return 1;
        }

        writeln(PackagerInfo.getContainerNamespace());
        return 0;
    }

    private int namespacePublish(string[] args) {
        if (args.length != 2) {
            stderr.writeln("Error: Command `namespace-publish` does not support any arguments.");
            return 1;
        }

        auto containerEngine = new ContainerEngine();

        foreach (image; containerEngine.listImages()) {
            if (!image.isOurs()) {
                continue;
            }

            if (!image.hasFullName()) {
                writeln("Warning: Skipping image `", image.id, "` with no full name.");
                continue;
            }

            containerEngine.pushImage(image.toString());
        }

        return 0;
    }

    private int namespaceRemoveAll(string[] args) {
        if (args.length != 2) {
            stderr.writeln("Error: Command `namespace-remove-all` does not support any arguments.");
            writeln("Hint: Use the environment variable `CONTAINER_NAMESPACE` to specify which namespace to expunge.");
            return 1;
        }

        auto containerEngine = new ContainerEngine();
        ContainerImage[] images;

        foreach (image; containerEngine.listImages()) {
            if (image.isOurs()) {
                images ~= image;
            }
        }

        string[] toRemove;
        foreach (img; images) {
            string s = img.toString();
            if (!toRemove.canFind(s)) {
                toRemove ~= s;
            }
        }

        containerEngine.removeImages(false, toRemove);
        return 0;
    }

    private int tag(string[] args) {
        auto engine = new ContainerEngine();
        auto tagger = new Tagger(engine);
        tagger.applyAll();
        return 0;
    }
}

int main(string[] args) {
    auto app = new App();
    return app.run(args);
}
