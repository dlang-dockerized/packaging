module ddct.datatype;

import std.typecons : Nullable;
import ddct.path : Path;

@safe:

enum VersionSpecifierType {
    Null,
    Branch,
    Commit,
    SemanticTag
}

struct Branch {
    string name;

    static Branch* parse(string value) @safe {
        import std.algorithm : canFind;
        static const string[] validBranches = ["ci", "dev", "ltsmaster", "main", "master", "stable", "trunk"];
        if (validBranches.canFind(value)) {
            return new Branch(value);
        }
        return null;
    }

    int compareTo(const Branch b) const @safe {
        int na = (this.name == "stable") ? 0 : 1;
        int nb = (b.name == "stable") ? 0 : 1;
        if (na != nb) return na - nb;
        import std.algorithm : cmp;
        return cmp(this.name, b.name);
    }

    bool match(const Branch b) const @safe {
        return this.name == b.name;
    }
}

struct Commit {
    string id;

    static Commit* parse(string value) @safe {
        import std.ascii : isHexDigit;
        import std.algorithm : all;
        if (value.length > 40 || value.length == 0 || !value.all!isHexDigit) {
            return null;
        }
        return new Commit(value);
    }

    int compareTo(const Commit b) const @safe {
        import std.algorithm : cmp;
        return cmp(this.id, b.id);
    }

    bool match(const Commit b) const @safe {
        import std.algorithm : startsWith;
        return this.id.startsWith(b.id) || b.id.startsWith(this.id);
    }
}

int naturalCmp(string a, string b) @safe {
    import std.ascii : isDigit;
    size_t i = 0, j = 0;
    while (i < a.length && j < b.length) {
        if (isDigit(a[i]) && isDigit(b[j])) {
            size_t iStart = i;
            while (i < a.length && isDigit(a[i])) i++;
            size_t jStart = j;
            while (j < b.length && isDigit(b[j])) j++;

            string numA = a[iStart .. i];
            string numB = b[jStart .. j];

            while (numA.length > 1 && numA[0] == '0') numA = numA[1 .. $];
            while (numB.length > 1 && numB[0] == '0') numB = numB[1 .. $];

            if (numA.length != numB.length) {
                return (numA.length < numB.length) ? -1 : 1;
            }
            import std.algorithm : cmp;
            int c = cmp(numA, numB);
            if (c != 0) return c;
        } else {
            if (a[i] != b[j]) {
                return (a[i] < b[j]) ? -1 : 1;
            }
            i++;
            j++;
        }
    }
    if (i < a.length) return 1;
    if (j < b.length) return -1;
    return 0;
}

struct SemVer {
    int major;
    Nullable!int minor;
    Nullable!int patch;
    string preRelease;
    string buildMetadata;

    string toString() const @safe {
        import std.conv : to;
        string s = major.to!string;
        s ~= "." ~ (minor.isNull ? "*" : minor.get.to!string);
        s ~= "." ~ (patch.isNull ? "*" : patch.get.to!string);
        if (preRelease.length > 0) {
            s ~= "-" ~ preRelease;
        }
        if (buildMetadata.length > 0) {
            s ~= "+" ~ buildMetadata;
        }
        return s;
    }

    string toDmString() const @safe {
        import std.conv : to;
        import std.format : format;
        string s = major.to!string;
        s ~= "." ~ (minor.isNull ? "*" : format("%03d", minor.get));
        s ~= "." ~ (patch.isNull ? "*" : patch.get.to!string);
        if (preRelease.length > 0) {
            s ~= "-" ~ preRelease;
        }
        if (buildMetadata.length > 0) {
            s ~= "+" ~ buildMetadata;
        }
        return s;
    }

    static SemVer* parse(string input) @safe {
        import std.regex;
        import std.conv : to;

        string val = input;
        if (val.length > 0 && val[0] == 'v') {
            val = val[1 .. $];
        }

        auto r = ctRegex!(r"^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$");
        auto m = matchFirst(val, r);
        if (m.empty) {
            return null;
        }

        try {
            int maj = m["major"].to!int;
            int min = m["minor"].to!int;
            int pat = m["patch"].to!int;
            string pre = m["prerelease"];
            string build = m["buildmetadata"];
            return new SemVer(maj, Nullable!int(min), Nullable!int(pat), pre, build);
        } catch (Exception) {
            return null;
        }
    }

    static SemVer* parseLax(string input) @safe {
        import std.regex;
        import std.conv : to;

        string val = input;
        if (val.length > 0 && val[0] == 'v') {
            val = val[1 .. $];
        }

        auto r = ctRegex!(r"^(?P<major>\d*)(?:\.(?P<minor>[\d*]*))?(?:\.(?P<patch>[\d*]*))?(?:-(?P<prerelease>[0-9a-zA-Z.-]+))?(?:\+(?P<buildmetadata>[0-9a-zA-Z.-]+))?$");
        auto m = matchFirst(val, r);
        if (m.empty) {
            return null;
        }

        try {
            int maj = m["major"].to!int;
            Nullable!int min;
            if (!m["minor"].empty && m["minor"] != "*") {
                min = m["minor"].to!int;
            }
            Nullable!int pat;
            if (!m["patch"].empty && m["patch"] != "*") {
                pat = m["patch"].to!int;
            }
            string pre = m["prerelease"];
            string build = m["buildmetadata"];
            return new SemVer(maj, min, pat, pre, build);
        } catch (Exception) {
            return null;
        }
    }

    int compareTo(const SemVer b) const @safe {
        int maj = compareComponent(this.major, b.major);
        if (maj != 0) return maj;

        int min = compareComponent(this.minor, b.minor);
        if (min != 0) return min;

        int pat = compareComponent(this.patch, b.patch);
        if (pat != 0) return pat;

        int preReA = (this.preRelease.length == 0) ? 1 : 0;
        int preReB = (b.preRelease.length == 0) ? 1 : 0;
        int preReleaseComp = preReA - preReB;
        if (preReleaseComp != 0) return preReleaseComp;

        if (this.preRelease.length > 0) {
            return naturalCmp(this.preRelease, b.preRelease);
        }
        return 0;
    }

    static int compareComponent(Nullable!int a, Nullable!int b) @safe {
        int valA = a.isNull ? int.max : a.get;
        int valB = b.isNull ? int.max : b.get;
        if (valA < valB) return -1;
        if (valA > valB) return 1;
        return 0;
    }

    static int compareComponent(int a, int b) @safe {
        if (a < b) return -1;
        if (a > b) return 1;
        return 0;
    }

    bool match(const SemVer b) const @safe {
        if (!matchComponent(this.major, b.major)) return false;
        if (!matchComponent(this.minor, b.minor)) return false;
        if (!matchComponent(this.patch, b.patch)) return false;
        if (!matchComponent(this.preRelease, b.preRelease)) return false;
        if (!matchComponent(this.buildMetadata, b.buildMetadata)) return false;
        return true;
    }

    static bool matchComponent(Nullable!int a, Nullable!int b) @safe {
        if (a.isNull || b.isNull) return true;
        return a.get == b.get;
    }

    static bool matchComponent(int a, int b) @safe {
        return a == b;
    }

    static bool matchComponent(string a, string b) @safe {
        if (a.length == 0 || b.length == 0) return true;
        return a == b;
    }
}

struct VersionSpecifier {
    VersionSpecifierType type;
    Branch branch;
    Commit commit;
    SemVer semanticTag;

    string toString() const @safe {
        final switch (type) {
            case VersionSpecifierType::Null: return "_";
            case VersionSpecifierType::Branch: return branch.name;
            case VersionSpecifierType::Commit: return commit.id;
            case VersionSpecifierType::SemanticTag: return semanticTag.toString();
        }
    }

    bool isBranch() const @safe { return type == VersionSpecifierType::Branch; }
    bool isCommit() const @safe { return type == VersionSpecifierType::Commit; }
    bool isSemanticTag() const @safe { return type == VersionSpecifierType::SemanticTag; }
    bool isNull() const @safe { return type == VersionSpecifierType::Null; }

    static VersionSpecifier parse(string value, bool parseSemanticVersionLax = false) @safe {
        if (parseSemanticVersionLax) {
            auto sem = SemVer.parseLax(value);
            if (sem !is null) return VersionSpecifier(VersionSpecifierType::SemanticTag, Branch.init, Commit.init, *sem);
        } else {
            auto sem = SemVer.parse(value);
            if (sem !is null) return VersionSpecifier(VersionSpecifierType::SemanticTag, Branch.init, Commit.init, *sem);
        }

        auto br = Branch.parse(value);
        if (br !is null) return VersionSpecifier(VersionSpecifierType::Branch, *br, Commit.init, SemVer.init);

        auto co = Commit.parse(value);
        if (co !is null) return VersionSpecifier(VersionSpecifierType::Commit, Branch.init, *co, SemVer.init);

        return VersionSpecifier(VersionSpecifierType::Null, Branch.init, Commit.init, SemVer.init);
    }

    int prioritizeByType() const @safe {
        final switch (type) {
            case VersionSpecifierType::Null: return 0;
            case VersionSpecifierType::Branch: return 3;
            case VersionSpecifierType::Commit: return 1;
            case VersionSpecifierType::SemanticTag: return 2;
        }
    }

    static bool match(const VersionSpecifier a, const VersionSpecifier b) @safe {
        if (a.type != b.type) return false;
        final switch (a.type) {
            case VersionSpecifierType::Null: return true;
            case VersionSpecifierType::Branch: return a.branch.match(b.branch);
            case VersionSpecifierType::Commit: return a.commit.match(b.commit);
            case VersionSpecifierType::SemanticTag: return a.semanticTag.match(b.semanticTag);
        }
    }

    static int compare(const VersionSpecifier a, const VersionSpecifier b) @safe {
        if (a.type != b.type) {
            return a.prioritizeByType() - b.prioritizeByType();
        }
        final switch (a.type) {
            case VersionSpecifierType::Null: return 0;
            case VersionSpecifierType::Branch: return a.branch.compareTo(b.branch);
            case VersionSpecifierType::Commit: return a.commit.compareTo(b.commit);
            case VersionSpecifierType::SemanticTag: return a.semanticTag.compareTo(b.semanticTag);
        }
    }

    int compareTo(const VersionSpecifier b) const @safe {
        return compare(this, b);
    }
}

struct ContainerVersionTag {
    VersionSpecifier versionSpecifier;
    string baseImageAlias;

    string toString(bool includeBaseImageAlias = true) const @safe {
        import std.string : replace;
        final switch (versionSpecifier.type) {
            case VersionSpecifierType::Null:
                return includeBaseImageAlias ? "_-" ~ baseImageAlias : "_";
            case VersionSpecifierType::Branch:
                string data = versionSpecifier.branch.name.replace("-", "_");
                return (includeBaseImageAlias && baseImageAlias.length > 0) ? (data ~ "-" ~ baseImageAlias) : data;
            case VersionSpecifierType::Commit:
                string data = versionSpecifier.commit.id.replace("-", "_");
                return (includeBaseImageAlias && baseImageAlias.length > 0) ? (data ~ "-" ~ baseImageAlias) : data;
            case VersionSpecifierType::SemanticTag:
                return toStringImplSemanticTag(includeBaseImageAlias);
        }
    }

    private string toStringImplSemanticTag(bool includeBaseImageAlias) const @safe {
        import std.conv : to;
        auto semver = versionSpecifier.semanticTag;
        string s = semver.major.to!string;
        s ~= "." ~ (semver.minor.isNull ? "*" : semver.minor.get.to!string);
        s ~= "." ~ (semver.patch.isNull ? "*" : semver.patch.get.to!string);
        if (semver.preRelease.length > 0) {
            s ~= "_" ~ semver.preRelease;
        }
        if (includeBaseImageAlias && baseImageAlias.length > 0) {
            s ~= "-" ~ baseImageAlias;
        }
        return s;
    }

    bool isFullVersionNumber() const @safe {
        final switch (versionSpecifier.type) {
            case VersionSpecifierType::Null: return false;
            case VersionSpecifierType::Branch: return versionSpecifier.branch.name.length > 0;
            case VersionSpecifierType::Commit: return versionSpecifier.commit.id.length > 0;
            case VersionSpecifierType::SemanticTag:
                return !versionSpecifier.semanticTag.minor.isNull && !versionSpecifier.semanticTag.patch.isNull;
        }
    }

    static int compare(const ContainerVersionTag a, const ContainerVersionTag b) @safe {
        int naive = VersionSpecifier.compare(a.versionSpecifier, b.versionSpecifier);
        if (naive == 0) {
            if (a.baseImageAlias != b.baseImageAlias) {
                return naturalCmp(a.baseImageAlias, b.baseImageAlias);
            }
        }
        return naive;
    }

    int compareTo(const ContainerVersionTag b) const @safe {
        return compare(this, b);
    }

    static bool match(const ContainerVersionTag a, const ContainerVersionTag b) @safe {
        bool naive = VersionSpecifier.match(a.versionSpecifier, b.versionSpecifier);
        if (!naive) return false;
        if (a.baseImageAlias.length == 0 || b.baseImageAlias.length == 0) {
            return true;
        }
        return a.baseImageAlias == b.baseImageAlias;
    }

    static ContainerVersionTag* parse(string input) @safe {
        return parseImpl(input, false);
    }

    static ContainerVersionTag* parseLax(string input) @safe {
        return parseImpl(input, true);
    }

    private static ContainerVersionTag* parseImpl(string input, bool lax) @safe {
        string baseImageAlias;
        string remaining = input;
        if (!parseValidateAndConsumeBaseImageAlias(remaining, baseImageAlias)) {
            return null;
        }

        VersionSpecifierType type = parseDetermineType(remaining);
        VersionSpecifier spec;
        if (type == VersionSpecifierType::SemanticTag) {
            auto parsed = parseSemantic(remaining, lax);
            if (parsed is null) return null;
            spec = VersionSpecifier(type, Branch.init, Commit.init, *parsed);
        } else if (type == VersionSpecifierType::Branch) {
            auto parsed = Branch.parse(remaining);
            if (parsed is null) return null;
            spec = VersionSpecifier(type, *parsed, Commit.init, SemVer.init);
        } else if (type == VersionSpecifierType::Commit) {
            auto parsed = Commit.parse(remaining);
            if (parsed is null) return null;
            spec = VersionSpecifier(type, Branch.init, *parsed, SemVer.init);
        } else {
            return null;
        }

        return new ContainerVersionTag(spec, baseImageAlias);
    }

    private static bool parseValidateAndConsumeBaseImageAlias(ref string input, ref string baseImageAlias) @safe {
        import std.string : indexOf;
        import std.regex;
        ptrdiff_t idxSep = input.indexOf('-');
        if (idxSep == -1) {
            return true;
        }

        baseImageAlias = input[idxSep + 1 .. $];
        auto r = ctRegex!(`^[0-9a-zA-Z_-]+$`);
        if (matchFirst(baseImageAlias, r).empty) {
            return false;
        }

        input = input[0 .. idxSep];
        return true;
    }

    private static VersionSpecifierType parseDetermineType(string input) @safe {
        import std.string : indexOf;
        import std.algorithm : all;
        import std.ascii : isDigit, isHexDigit;

        if (input.indexOf('.') != -1) {
            return VersionSpecifierType::SemanticTag;
        }

        bool isNumeric = input.all!isDigit;
        size_t len = input.length;
        if (isNumeric && len < 7) {
            return VersionSpecifierType::SemanticTag;
        }

        bool isHex = input.all!isHexDigit;
        if (isHex && len <= 40) {
            return VersionSpecifierType::Commit;
        }

        return VersionSpecifierType::Branch;
    }

    private static SemVer* parseSemantic(string input, bool lax) @safe {
        import std.regex;
        import std.conv : to;
        import std.typecons : Nullable;

        if (lax) {
            auto r = ctRegex!(r"^(?P<major>\d*)(?:\.(?P<minor>[\d*]*))?(?:\.(?P<patch>[\d*]*))?(?:_(?P<prerelease>[0-9a-zA-Z_.]+))?$");
            auto m = matchFirst(input, r);
            if (m.empty) return null;
            int maj = m["major"].empty ? 0 : m["major"].to!int;
            Nullable!int min;
            if (!m["minor"].empty && m["minor"] != "*") {
                min = m["minor"].to!int;
            }
            Nullable!int pat;
            if (!m["patch"].empty && m["patch"] != "*") {
                pat = m["patch"].to!int;
            }
            string pre = m["prerelease"];
            return new SemVer(maj, min, pat, pre, "");
        } else {
            auto r = ctRegex!(r"^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:_(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z_][0-9a-zA-Z_]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z_][0-9a-zA-Z_]*))*))?$");
            auto m = matchFirst(input, r);
            if (m.empty) return null;
            int maj = m["major"].to!int;
            int min = m["minor"].to!int;
            int pat = m["patch"].to!int;
            string pre = m["prerelease"];
            return new SemVer(maj, Nullable!int(min), Nullable!int(pat), pre, "");
        }
    }
}

struct IniSection {
    string name;
    string[string] simpleKeys;
    string[] dependencies;
    string[] add;
    string[string] env;
    string[string] extras;
}

IniSection[string] parseIniFile(string filePath) @trusted {
    import std.file : readText, exists;
    import std.string : strip, split, startsWith, endsWith, indexOf;
    import std.exception : enforce;
    import std.path : basename;

    if (!exists(filePath)) {
        throw new Exception("Cannot load `" ~ basename(filePath) ~ "`: File `" ~ filePath ~ "` does not exist.");
    }

    string content;
    try {
        content = readText(filePath);
    } catch (Exception e) {
        throw new Exception("Bad `" ~ basename(filePath) ~ "`: Unable to read file contents.");
    }

    IniSection[string] sections;
    IniSection currentSection;
    bool inSection = false;

    auto lines = content.split("\n");
    foreach (lineNo, rawLine; lines) {
        string line = rawLine.strip();
        if (line.length == 0 || line.startsWith(";") || line.startsWith("#")) {
            continue;
        }

        if (line.startsWith("[") && line.endsWith("]")) {
            if (inSection) {
                sections[currentSection.name] = currentSection;
            }
            string secName = line[1 .. $-1].strip();
            currentSection = IniSection(secName);
            inSection = true;
        } else {
            if (!inSection) {
                throw new Exception("Bad `" ~ basename(filePath) ~ "`: Key-value pair found outside section on line " ~ (lineNo + 1).stringof);
            }
            ptrdiff_t eqIdx = line.indexOf('=');
            if (eqIdx == -1) {
                throw new Exception("Bad `" ~ basename(filePath) ~ "`: Missing '=' on line " ~ (lineNo + 1).stringof);
            }
            string key = line[0 .. eqIdx].strip();
            string val = line[eqIdx + 1 .. $].strip();

            if (val.startsWith("\"") && val.endsWith("\"") && val.length >= 2) {
                val = val[1 .. $-1];
            } else if (val.startsWith("'") && val.endsWith("'") && val.length >= 2) {
                val = val[1 .. $-1];
            }

            if (key == "dependencies[]") {
                currentSection.dependencies ~= val;
            } else if (key == "add[]") {
                currentSection.add ~= val;
            } else if (key.startsWith("env[") && key.endsWith("]")) {
                string subkey = key[4 .. $-1].strip();
                currentSection.env[subkey] = val;
            } else if (key.startsWith("extras[") && key.endsWith("]")) {
                string subkey = key[7 .. $-1].strip();
                currentSection.extras[subkey] = val;
            } else {
                currentSection.simpleKeys[key] = val;
            }
        }
    }
    if (inSection) {
        sections[currentSection.name] = currentSection;
    }
    return sections;
}

struct BaseImage {
    string alias;
    string image;
    string[string] env;

    static BaseImage resolve(string baseImageAlias) @safe {
        auto defs = parseIniFile(Path.baseImageDefinitionsFile);
        return resolveImpl(defs, baseImageAlias);
    }

    private static BaseImage resolveImpl(ref IniSection[string] baseImages, string baseImageAlias) @safe {
        auto pSec = baseImageAlias in baseImages;
        if (!pSec) {
            throw new Exception("The requested base-image `" ~ baseImageAlias ~ "` is not available.");
        }

        auto pAlias = "alias" in pSec.simpleKeys;
        if (pAlias) {
            return resolveImpl(baseImages, *pAlias);
        }

        auto pImg = "image" in pSec.simpleKeys;
        if (!pImg) {
            throw new Exception("Invalid base-image definition `" ~ baseImageAlias ~ "` specifies neither `image` nor `alias`.");
        }

        return BaseImage(baseImageAlias, *pImg, pSec.env);
    }
}

struct ContainerFileRecipe {
    string app;
    string version_;
    string languageLevel;
    string template_;
    string[string] env;
    string[] dependencies;
    string[string] extras;

    static ContainerFileRecipe fromSection(IniSection sec, string appName, string appVersion) @safe {
        string key = appName ~ ":" ~ appVersion;

        string lvl;
        auto pLvl = "level" in sec.simpleKeys;
        if (pLvl is null) {
            lvl = appVersion;
        } else if (*pLvl == "false") {
            lvl = "";
        } else {
            lvl = *pLvl;
        }

        string tpl;
        auto pTpl = "template" in sec.simpleKeys;
        if (pTpl is null) {
            tpl = appName ~ "/" ~ appName ~ "-image.containerfile";
        } else {
            tpl = *pTpl;
        }

        return ContainerFileRecipe(
            appName,
            appVersion,
            lvl,
            tpl,
            sec.env,
            sec.dependencies,
            sec.extras
        );
    }
}

struct ContainerFileMapEntry {
    VersionSpecifier versionSpecifier;
    ContainerFileRecipe recipe;
}

class AppVersionList {
    ContainerFileMapEntry[] branches;
    ContainerFileMapEntry[] commits;
    ContainerFileMapEntry[] semanticTags;

    void sort() @safe {
        import std.algorithm : sort;
        sort!((a, b) => b.versionSpecifier.semanticTag.compareTo(a.versionSpecifier.semanticTag) < 0)(this.semanticTags);
    }

    bool has(VersionSpecifier specifier) @safe {
        final switch (specifier.type) {
            case VersionSpecifierType::Null: return false;
            case VersionSpecifierType::Branch: return hasBranch(specifier.branch);
            case VersionSpecifierType::Commit: return hasCommit(specifier.commit);
            case VersionSpecifierType::SemanticTag: return hasSemanticTag(specifier.semanticTag);
        }
    }

    bool hasBranch(Branch branch) @safe {
        foreach (b; branches) {
            if (b.versionSpecifier.branch.name == branch.name) return true;
        }
        return false;
    }

    bool hasCommit(Commit commit) @safe {
        foreach (c; commits) {
            if (c.versionSpecifier.commit.match(commit)) return true;
        }
        return false;
    }

    bool hasSemanticTag(SemVer semanticTag) @safe {
        foreach (st; semanticTags) {
            if (st.versionSpecifier.semanticTag.compareTo(semanticTag) == 0) return true;
        }
        return false;
    }

    ContainerFileRecipe* match(VersionSpecifier specifier) @safe {
        final switch (specifier.type) {
            case VersionSpecifierType::Null: return null;
            case VersionSpecifierType::Branch: return matchBranch(specifier.branch);
            case VersionSpecifierType::Commit: return matchCommit(specifier.commit);
            case VersionSpecifierType::SemanticTag: return matchSemanticTag(specifier.semanticTag);
        }
    }

    ContainerFileRecipe* matchBranch(Branch branch) @safe {
        foreach (ref b; branches) {
            if (b.versionSpecifier.branch.name == branch.name) return &b.recipe;
        }
        return null;
    }

    ContainerFileRecipe* matchCommit(Commit commit) @safe {
        foreach (ref c; commits) {
            if (c.versionSpecifier.commit.match(commit)) return &c.recipe;
        }
        return null;
    }

    ContainerFileRecipe* matchSemanticTag(SemVer semanticTag) @safe {
        foreach (ref st; semanticTags) {
            if (st.versionSpecifier.semanticTag.match(semanticTag)) return &st.recipe;
        }
        return null;
    }

    void push(ContainerFileMapEntry entry) @safe {
        final switch (entry.versionSpecifier.type) {
            case VersionSpecifierType::Null: break;
            case VersionSpecifierType::Branch: branches ~= entry; break;
            case VersionSpecifierType::Commit: commits ~= entry; break;
            case VersionSpecifierType::SemanticTag: semanticTags ~= entry; break;
        }
    }
}

class AppVersionAppList {
    AppVersionList[string] data;

    void push(string appName, ContainerFileMapEntry entry) @safe {
        if (appName !in data) {
            data[appName] = new AppVersionList();
        }
        data[appName].push(entry);
    }

    bool has(string appName) @safe {
        return (appName in data) !is null;
    }

    AppVersionList get(string appName) @safe {
        auto p = appName in data;
        return p ? *p : null;
    }

    void sort() @safe {
        foreach (appVersionList; data.values) {
            appVersionList.sort();
        }
    }
}

class ContainerFileMap {
    AppVersionAppList data;

    this(AppVersionAppList data) @safe {
        this.data = data;
    }

    bool has(string name, VersionSpecifier version_) @safe {
        return get(name, version_) !is null;
    }

    ContainerFileRecipe* get(string name, VersionSpecifier version_) @safe {
        auto appVersionList = data.get(name);
        if (appVersionList is null) return null;
        return appVersionList.match(version_);
    }

    ContainerFileRecipe* getByKey(string key, bool parseLax = true) @safe {
        import ddct.util.containerfile : ContainerFile;
        auto parsedKey = ContainerFile.parseKey(key);
        if (parsedKey.length == 0) return null;

        auto version_ = VersionSpecifier.parse(parsedKey[1], parseLax);
        if (version_.isNull()) return null;

        return get(parsedKey[0], version_);
    }

    AppVersionList getAllByName(string name) @safe {
        return data.get(name);
    }

    static ContainerFileMap parseDefinitions(IniSection[string] definitions) @safe {
        import std.stdio : writeln;
        import ddct.util.containerfile : ContainerFile;
        auto tree = new AppVersionAppList();

        foreach (key, recipeRaw; definitions) {
            auto keyData = ContainerFile.parseKey(key);
            if (keyData.length != 2) continue;
            string appName = keyData[0];
            string appVersion = keyData[1];
            auto version_ = VersionSpecifier.parse(appVersion);

            if (version_.isNull()) {
                writeln("Warning: Ignoring Containerfile recipe with invalid version specifier `", key, "`.");
                continue;
            }

            auto appVersionList = tree.get(appName);
            if (appVersionList !is null) {
                if (appVersionList.has(version_)) {
                    writeln("Warning: Skipping duplicate or ambiguous Containerfile recipe entry `", key, "`.");
                    continue;
                }
            }

            auto recipe = ContainerFileRecipe.fromSection(recipeRaw, appName, appVersion);
            auto entry = ContainerFileMapEntry(version_, recipe);
            tree.push(appName, entry);
        }

        tree.sort();
        return new ContainerFileMap(tree);
    }
}
