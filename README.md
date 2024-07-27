# dlang-dockerized

## Quickstart

```sh
# optionally generate all available Containerfiles in advance.
./ddct generate-all

# Build container images.
./ddct build ldc 1.39
./ddct build dmd 2.107
```

## Manual

### Container Toolkit

`./ddct` as the dlang-dockerized Container Toolkit is a helper tool
for managing Containerfiles and images.
It wraps container management engines (docker, podman)
and uses the runtime’s built-in template engine.

DDCT supports dependency resolution for the bootstrapping process,
so it will automatically build other container images required for bootstrapping
the requested one.

#### Getting started

Run `./ddct help` to get a list of available commands.

#### Important Commands

- `./ddct generate-all [<base-image>]`
	- Generates all available Containerfiles for the current base-image.
- `./ddct detect-engine`
	- Determines which container management engine will be used.
	- The engine can be overriden by passing the environment variable `CONTAINER_ENGINE`.
	  For example, `CONTAINER_ENGINE=podman ./ddct detect-engine` will print `podman`,
	  if `podman` happens to be available.
- `./ddct build <app> <version> [<base-image>]`
	- Builds the specified container image.
	- Use the environment variable `CONTAINER_ENGINE` to override the container engine to be used.

#### Tips and tricks

##### Using `sudo`, `doas` or similar

When running *ddct* with *sudo*, *doas* or similar setuid helpers,
beware of the placement of environment variables.
Usually those are configured to not forward arbitrary environment variables.
Instead the user has to explicitly pass the desired variables through a special mechanism.

- `CONTAINER_NAMESPACE=my-namespace sudo ./ddct namespace-echo` – ***wrong***
- `sudo CONTAINER_NAMESPACE=my-namespace ./ddct namespace-echo` – ***correct***

##### Docker build log output

When using the newer *buildx* container builder
that is the default in newer versions of docker,
there are several eye candy features that may be making it difficult to debug
build issues.
For example it hides the output from previous commands,
paginates the output of the currently running one
and even clips it, once it gets longer than a preconfigured limit.

Set the environment variable `BUILDKIT_PROGRESS` to `plain`,
to tune the status output to a conservative line-by-line log.

E.g. `BUILDKIT_PROGRESS=plain ./ddct build …`


### Adding new compiler versions

Containerfile definitions are stored
in [`definitions/containerfiles.ini`](./definitions/containerfiles.ini).

The version supplied by this repo contains a detailed description
about the structure of this file.

To determine which version of DUB to bundle with which compiler version,
the accompanying scripts, `./tools/determine-dub-version-of-dmd-release.sh` and
`./tools/determine-dub-version-of-ldc-release.sh`, can be used.


## Bootstrapping pipeline

While no longer up-to-date,
this sketch outlines how the bootstrapping process works.

```
system gcc → build ldc lts ← custom llvm 7
                    ↓
system gcc → build ldc 1.20 ← custom llvm 10
                    ↓
system gcc → build ldc stable ← custom llvm 15+
                    ↓
system gcc → build ldc stable (again) ← custom llvm 15+
                    ↓
system gcc → build any other compilers
```
