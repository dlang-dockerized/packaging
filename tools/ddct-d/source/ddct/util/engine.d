module ddct.util.engine;

import std.string;
import std.algorithm;
import std.json;
import std.exception;

import ddct.datatype;
import ddct.util.process;
import ddct.util.containerfile : PackagerInfo;

@safe:

struct ContainerImage {
    string id;
    string repository;
    string tag;

    string getNamespace() const @safe {
        ptrdiff_t idxSep = repository.lastIndexOf('/');
        if (idxSep == -1) return "";
        return repository[0 .. idxSep];
    }

    string getName() const @safe {
        ptrdiff_t idxSep = repository.lastIndexOf('/');
        if (idxSep == -1) return "";
        return repository[idxSep + 1 .. $];
    }

    ContainerVersionTag* parseVersionTag() const @safe {
        return ContainerVersionTag.parseLax(tag);
    }

    bool isOurs() const @safe {
        return getNamespace() == PackagerInfo.getContainerNamespace();
    }

    bool hasFullName() const @safe {
        return getName().length > 0 && getNamespace().length > 0 && tag.length > 0;
    }

    string toString() const @safe {
        if (repository.length > 0 && tag.length > 0) {
            return repository ~ ":" ~ tag;
        }
        return id;
    }

    static ContainerImage fromJson(string jsonStr) @safe {
        try {
            JSONValue val = parseJSON(jsonStr);
            string idVal = "";
            if ("ID" in val) idVal = val["ID"].str;
            else if ("id" in val) idVal = val["id"].str;

            string repoVal = "";
            if ("Repository" in val) repoVal = val["Repository"].str;
            else if ("repository" in val) repoVal = val["repository"].str;

            string tagVal = "";
            if ("Tag" in val) tagVal = val["Tag"].str;
            else if ("tag" in val) tagVal = val["tag"].str;

            return ContainerImage(idVal, repoVal, tagVal);
        } catch (Exception) {
            return ContainerImage.init;
        }
    }
}

class ContainerEngine {
    private string containerEngine;

    this(string engine = "") {
        if (engine.length == 0) {
            auto detected = detectContainerEngine();
            if (detected.length == 0) {
                throw new Exception("No `CONTAINER_ENGINE` specified. Auto-detection failed.");
            }
            containerEngine = detected;
        } else {
            containerEngine = engine;
        }
    }

    string getEnginePath() const @safe {
        return containerEngine;
    }

    void build(string containerfilePath, string tag) @safe {
        string[] args = ["build", "-f", containerfilePath, "."];
        if (tag.length > 0) {
            args ~= "--tag";
            args ~= tag;
        }
        passthruCommand(containerEngine, args);
    }

    ContainerImage[] listImages() @safe {
        auto res = executeCommand(containerEngine, ["images", "--format={{ json . }}"]);
        ContainerImage[] list;
        foreach (line; res.outputLines) {
            string s = line.strip();
            if (s.length == 0) continue;
            auto img = ContainerImage.fromJson(s);
            if (img.id.length > 0 || img.repository.length > 0) {
                list ~= img;
            }
        }
        return list;
    }

    void tagImage(string sourceImage, string tag) @safe {
        passthruCommand(containerEngine, ["tag", sourceImage, tag]);
    }

    void removeImages(bool force, string[] images) @safe {
        if (images.length == 0) return;
        string[] args = ["rmi"];
        if (force) {
            args ~= "--force";
        }
        args ~= images;
        passthruCommand(containerEngine, args);
    }

    void pruneImages() @safe {
        passthruCommand(containerEngine, ["image", "prune", "--force"]);
    }

    void pushImage(string name) @safe {
        passthruCommand(containerEngine, ["push", name]);
    }

    private string getArchDocker() @safe {
        auto res = executeCommand(containerEngine, ["version", "--format={{ json .Server.Arch }}"]);
        if (res.outputLines.length == 0) throw new Exception("No data received.");
        try {
            return parseJSON(res.outputLines[0]).str;
        } catch (Exception) {
            return res.outputLines[0].strip();
        }
    }

    private string getArchPodman() @safe {
        auto res = executeCommand(containerEngine, ["version", "--format={{ json .OsArch }}"]);
        if (res.outputLines.length == 0) throw new Exception("No data received.");
        try {
            string osArch = parseJSON(res.outputLines[0]).str;
            auto parts = osArch.split("/");
            if (parts.length > 0) return parts[$ - 1];
            return osArch;
        } catch (Exception) {
            string osArch = res.outputLines[0].strip();
            auto parts = osArch.split("/");
            if (parts.length > 0) return parts[$ - 1];
            return osArch;
        }
    }

    string getArch() @safe {
        import std.string : indexOf;
        if (containerEngine.indexOf("docker") != -1) {
            return getArchDocker();
        }
        if (containerEngine.indexOf("podman") != -1) {
            return getArchPodman();
        }

        try {
            return getArchDocker();
        } catch (Exception) {}

        try {
            return getArchPodman();
        } catch (Exception) {}

        throw new Exception("Unable to determine CPU architecture of container engine.");
    }

    static string detectContainerEngine() @trusted {
        import std.process : environment;
        string engine = environment.get("CONTAINER_ENGINE");
        if (engine.length > 0) {
            if (!hasApplication(engine)) {
                throw new Exception("The requested `CONTAINER_ENGINE` (`" ~ engine ~ "`) is not available.");
            }
            return engine;
        }
        if (hasApplication("docker")) return "docker";
        if (hasApplication("podman")) return "podman";
        return "";
    }

    private static bool hasApplication(string name) @trusted {
        import std.process : execute;
        try {
            auto res = execute([name, "--version"]);
            return res.status == 0;
        } catch (Exception) {
            return false;
        }
    }
}
