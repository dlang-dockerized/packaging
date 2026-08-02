module ddct.util.tagger;

import std.string;
import std.algorithm;
import std.exception;

import ddct.datatype;
import ddct.util.engine;

@safe:

class TagMapBuilder {
    private string defaultBaseImageAlias;
    private string[][string] data;
    private string repository;
    private int previousMajor;
    private int previousMinor;
    private bool firstInRepository;

    this() {
        defaultBaseImageAlias = BaseImage.resolve("default").alias;
    }

    string[][string] getData() @safe {
        return data;
    }

    void nextRepository(string repo) @safe {
        repository = repo;
        previousMajor = int.max;
        previousMinor = int.max;
        firstInRepository = true;
    }

    void add(ContainerVersionTag versionTag) @safe {
        if (repository.length == 0) {
            throw new Exception("nextRepository() must be called before add().");
        }

        final switch (versionTag.versionSpecifier.type) {
            case VersionSpecifierType::Null:
                throw new Exception("Cannot add() a ContainerVersionTag of type Null.");
            case VersionSpecifierType::Branch:
            case VersionSpecifierType::Commit:
                addGeneric(versionTag);
                break;
            case VersionSpecifierType::SemanticTag:
                addSemanticTag(versionTag);
                break;
        }
    }

    void addGeneric(ContainerVersionTag versionTag) @safe {
        string source = repository ~ ":" ~ versionTag.toString(true);
        pushString(source, versionTag.baseImageAlias, versionTag.versionSpecifier.toString());
    }

    void addSemanticTag(ContainerVersionTag versionTag) @safe {
        string source = repository ~ ":" ~ versionTag.toString(true);
        auto version_ = versionTag.versionSpecifier.semanticTag;

        if (firstInRepository) {
            if (version_.preRelease.length == 0) {
                firstInRepository = false;
            }
            pushString(source, versionTag.baseImageAlias, "latest");
        }

        if (version_.major < previousMajor) {
            if (version_.preRelease.length == 0) {
                previousMajor = version_.major;
            }
            previousMinor = int.max;
            pushSemanticTag(source, versionTag.baseImageAlias, version_, 1);
        }

        if (!version_.minor.isNull && version_.minor.get < previousMinor) {
            previousMinor = version_.minor.get;
            pushSemanticTag(source, versionTag.baseImageAlias, version_, 2);
        }

        pushSemanticTag(source, versionTag.baseImageAlias, version_, 3);
    }

    private void pushSemanticTag(string source, string baseImageAlias, SemVer version_, int depth) @safe {
        import std.conv : to;
        string versionString;
        if (depth == 1) {
            versionString = version_.major.to!string;
        } else if (depth == 2) {
            versionString = version_.major.to!string ~ "." ~ version_.minor.get.to!string;
        } else {
            versionString = version_.toString();
        }
        pushString(source, baseImageAlias, versionString);
    }

    private void pushString(string source, string baseImageAlias, string version_) @safe {
        string tagShort = repository ~ ":" ~ version_;
        string tagFull = tagShort ~ "-" ~ baseImageAlias;

        // Push unique values
        if (!data.canFind(source) || !data[source].canFind(tagFull)) {
            data[source] ~= tagFull;
        }

        bool usesDefaultBaseImage = (baseImageAlias == defaultBaseImageAlias);
        if (usesDefaultBaseImage) {
            if (!data[source].canFind(tagShort)) {
                data[source] ~= tagShort;
            }
        }
    }
}

class Tagger {
    private ContainerEngine containerEngine;

    this(ContainerEngine engine) {
        this.containerEngine = engine;
    }

    void applyAll() @safe {
        auto tags = determineTags();
        applyTags(tags);
    }

    void applyTags(string[][string] tags) @safe {
        foreach (source, targets; tags) {
            foreach (tag; targets) {
                containerEngine.tagImage(source, tag);
            }
        }
    }

    string[][string] determineTags() @safe {
        auto images = containerEngine.listImages();
        return determineTagsForImages(images);
    }

    static string[][string] determineTagsForImages(ContainerImage[] images) @safe {
        auto tree = determineTagsTreeForImages(images);
        return determineTagsForTree(tree);
    }

    static ContainerVersionTag[][string] determineTagsTreeForImages(ContainerImage[] images) @safe {
        ContainerVersionTag[][string] tree;

        foreach (image; images) {
            if (!image.isOurs() || image.tag.length == 0) {
                continue;
            }

            auto version_ = image.parseVersionTag();
            if (version_ is null || version_.baseImageAlias.length == 0) {
                continue;
            }

            tree[image.repository] ~= *version_;
        }

        // Sort descending
        foreach (repo, ref list; tree) {
            sort!((a, b) => b.compareTo(a) < 0)(list);
        }

        return tree;
    }

    static string[][string] determineTagsForTree(ContainerVersionTag[][string] tree) @safe {
        auto tagMapBuilder = new TagMapBuilder();

        foreach (repo, versionList; tree) {
            tagMapBuilder.nextRepository(repo);
            foreach (versionTag; versionList) {
                tagMapBuilder.add(versionTag);
            }
        }

        return tagMapBuilder.getData();
    }
}
