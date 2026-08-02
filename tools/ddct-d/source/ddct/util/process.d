module ddct.util.process;

import std.process;
import std.string;
import std.exception;
import std.regex;
import std.algorithm;

@safe:

// Sanitized environment variables configuration.
// Only explicitly allowed variables will be forwarded.
private string[string] getSanitizedEnv() @trusted {
    import std.process : environment;
    string[string] cleanEnv;

    // Allow list of environment variables
    static const string[] allowList = ["PATH", "BUILDKIT_PROGRESS", "CONTAINER_ENGINE", "CONTAINER_NAMESPACE", "AUTO_PRUNE_IMAGES", "TPL_DEBUG", "TERM", "LANG", "LC_ALL"];

    foreach (var; allowList) {
        string val = environment.get(var);
        if (val.length > 0) {
            cleanEnv[var] = val;
        }
    }

    return cleanEnv;
}

// Check engine name validity to avoid execution vulnerabilities
bool isValidEngineName(string engine) @safe {
    import std.regex;
    auto r = ctRegex!(`^[a-zA-Z0-9_\-\./]+$`);
    return !matchFirst(engine, r).empty;
}

// Trusted execution wrapper result
struct ProcessResult {
    int status;
    string[] outputLines;
}

ProcessResult executeCommand(string engine, string[] args) @trusted {
    import std.stdio : stderr, stdout;
    import std.string : splitLines;

    if (!isValidEngineName(engine)) {
        throw new Exception("Security Violation: Invalid container engine name/path: " ~ engine);
    }

    string[] cmd = [engine] ~ args;
    auto cleanEnv = getSanitizedEnv();

    auto res = execute(cmd, cleanEnv);

    if (res.status != 0) {
        throw new Exception("Command `" ~ cmd.join(" ") ~ "` failed with status `" ~ res.status.stringof ~ "`: " ~ res.output);
    }

    return ProcessResult(res.status, res.output.splitLines());
}

int passthruCommand(string engine, string[] args) @trusted {
    import std.stdio : stdin, stdout, stderr;
    if (!isValidEngineName(engine)) {
        throw new Exception("Security Violation: Invalid container engine name/path: " ~ engine);
    }

    string[] cmd = [engine] ~ args;
    auto cleanEnv = getSanitizedEnv();

    auto pid = spawnProcess(cmd, cleanEnv);
    int status = wait(pid);
    if (status != 0) {
        throw new Exception("Command `" ~ cmd.join(" ") ~ "` failed with status `" ~ status.stringof ~ "`.");
    }
    return status;
}
