###############
# build stage #
###############

FROM {{ $BASE_IMAGE }} AS build-stage

WORKDIR /opt/build

# Install dependencies
{{< common/install-common-system-tools.containerfile }}
{{< common/install-llvm-build-deps.containerfile }}

# Download, build and install LLVM
{{< common/download-llvm-source.containerfile }}
{{< common/build-llvm.containerfile }}

################
# export stage #
################

FROM docker.io/debian:bookworm AS export-stage

COPY --from=build-stage /opt/llvm/ /opt/llvm/

CMD ["echo", "This image is not meant to be run. It only provides files located in /opt/llvm."]
