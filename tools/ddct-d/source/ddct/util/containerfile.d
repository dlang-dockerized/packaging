module ddct.util.containerfile;

import std.string;
import std.path;
import std.file;
import std.algorithm;

import ddct.datatype;
import ddct.path : Path;
import ddct.util.template;

@safe:

final class PackagerInfo {
    static string getContainerNamespace() @trusted {
        import std.process : environment;
        string ns = environment.get("CONTAINER_NAMESPACE");
        return ns.length == 0 ? "dlang-dockerized" : ns;
    }
}

struct VariablesDerivator {
    string appName;
    VersionSpecifier version_;
    VersionSpecifier languageLevel;
    BaseImage baseImage;
    string[] dependencies;
    string[string] extras;

    void applyVariables(void delegate(string, Val) @safe receiver) const {
        receiver("container_namespace", Val(PackagerInfo.getContainerNamespace()));
        receiver("app_name", Val(appName));
        receiver("base_image", Val(baseImage.image));
        receiver("base_image_alias", Val(baseImage.alias));
        receiver("version", Val(version_));

        final switch (version_.type) {
            case VersionSpecifierType::Null:
                break;
            case VersionSpecifierType::Commit:
                receiver("commit", Val(version_.commit));
                receiver("version_string", Val(version_.toString()));
                break;
            case VersionSpecifierType::Branch:
                receiver("branch", Val(version_.branch));
                receiver("version_string", Val(version_.toString()));
                break;
            case VersionSpecifierType::SemanticTag:
                receiver("semver", Val(version_.semanticTag));
                string versionString = (appName == "dmd")
                    ? version_.semanticTag.toDmString()
                    : version_.semanticTag.toString();
                receiver("version_string", Val(versionString));
                break;
        }

        if (!languageLevel.isNull()) {
            string languageLevelString = (languageLevel.type == VersionSpecifierType::SemanticTag)
                ? languageLevel.semanticTag.toDmString()
                : languageLevel.toString();
            receiver("language_level", Val(languageLevel));
            receiver("language_level_string", Val(languageLevelString));
        }

        Val[string] dependenciesAA;
        Val[string] dependenciesVersionAA;
        foreach (dependency; dependencies) {
            auto parsed = ContainerFile.parseKey(dependency);
            if (parsed.length != 2) continue;

            if (parsed[0] in dependenciesVersionAA) {
                throw new Exception("Duplicate dependency entry: " ~ parsed[0]);
            }
            dependenciesAA[parsed[0]] = Val(parsed[1]);
            dependenciesVersionAA[parsed[0]] = Val(VersionSpecifier.parse(parsed[1], true));
        }
        receiver("dependencies", Val(dependenciesAA));
        receiver("dependenciesVersion", Val(dependenciesVersionAA));

        Val[string] extrasAA;
        foreach (extra, ver; extras) {
            extrasAA[extra] = Val(VersionSpecifier.parse(ver));
        }
        receiver("extras", Val(extrasAA));
    }
}

class ContainerFile {
    static string[] parseKey(string key) @safe {
        import std.string : split;
        auto parts = key.split(":");
        if (parts.length != 2) return [];
        return parts;
    }

    static ContainerFileRecipe loadRecipe(string appName, string appVersion) @safe {
        auto defs = parseIniFile(Path.containerFileDefinitionsFile);
        string key = appName ~ ":" ~ appVersion;
        auto pSec = key in defs;
        if (!pSec) {
            throw new Exception("No recipe available for the requested Containerfile `" ~ key ~ "`.");
        }
        return ContainerFileRecipe.fromSection(*pSec, appName, appVersion);
    }

    static string getContainerFileTargetDir(string appName, string appVersion, BaseImage baseImage) @safe {
        return Path.containerFilesOutputDir ~ "/" ~ appName ~ "/" ~ appVersion ~ "/" ~ baseImage.alias;
    }

    static string getContainerFileTargetPath(string appName, string appVersion, BaseImage baseImage) @safe {
        return getContainerFileTargetDir(appName, appVersion, baseImage) ~ "/Containerfile";
    }

    static string generateFile(string appName, string appVersion, string baseImageAlias) @safe {
        auto baseImage = BaseImage.resolve(baseImageAlias);
        auto recipe = loadRecipe(appName, appVersion);
        auto version_ = VersionSpecifier.parse(appVersion);
        auto languageLevel = recipe.languageLevel.length > 0
            ? VersionSpecifier.parse(recipe.languageLevel, true)
            : VersionSpecifier(VersionSpecifierType::Null);

        string containerFileDir = getContainerFileTargetDir(appName, appVersion, baseImage);
        string containerFilePath = containerFileDir ~ "/Containerfile";

        // Path traversal protection check
        validateOutputPath(containerFilePath);

        // Ensure target directory exists securely
        ensureDirectoryExists(containerFileDir);

        // Populate initial variables from env (like patch files, distro etc.)
        Val[string] tplVars;
        foreach (k, v; recipe.env) {
            tplVars[k] = Val(v);
        }
        foreach (k, v; baseImage.env) {
            tplVars[k] = Val(v);
        }

        // Apply derived variables
        auto derivator = VariablesDerivator(
            appName, version_, languageLevel, baseImage,
            recipe.dependencies, recipe.extras
        );
        derivator.applyVariables((k, v) {
            tplVars[k] = v;
        });

        auto engine = new TemplateEngine(Path.templatesDir);
        string rendered = engine.render(recipe.template_, tplVars);

        writeRenderedFile(containerFilePath, rendered);

        return containerFilePath;
    }

    private static void validateOutputPath(string outputPath) @trusted {
        import std.path : canonicalPath, absolutePath, dirSeparator;
        import std.algorithm : startsWith;

        string targetDir = canonicalPath(absolutePath(Path.containerFilesOutputDir));
        string resolvedPath = canonicalPath(absolutePath(outputPath));

        string prefixWithSep = targetDir ~ dirSeparator;
        if (resolvedPath != targetDir && !resolvedPath.startsWith(prefixWithSep)) {
            throw new Exception("Security Violation: Path traversal detected in output file path: " ~ outputPath);
        }
    }

    private static void ensureDirectoryExists(string dirPath) @trusted {
        import std.file : exists, mkdirRecurse;
        if (!exists(dirPath)) {
            mkdirRecurse(dirPath);
        }
    }

    private static void writeRenderedFile(string filePath, string content) @trusted {
        import std.stdio : File;
        // Open file with write mode and write content securely (minimizes TOCTOU symlink injection risk)
        auto f = File(filePath, "w");
        f.rawWrite(content);
        f.close();
    }
}
