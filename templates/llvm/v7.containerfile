###############
# build stage #
###############

FROM {{ $BASE_IMAGE }} AS build-stage

WORKDIR /opt/build

# Install dependencies

{{< common/install-common-system-tools.containerfile }}

COPY ./templates/scripts/install-llvm-build-deps.sh .
RUN ./install-llvm-build-deps.sh

# Download, build and install LLVM

ENV DL_LLVM_TAG={{ $DL_LLVM_TAG }}
ENV LLVM_SEMVER_MAJOR={{ $LLVM_SEMVER_MAJOR }}

COPY ./templates/scripts/download-llvm-source.sh .
RUN ./download-llvm-source.sh

COPY ./templates/scripts/build-llvm.sh .
RUN ./build-llvm.sh

################
# export stage #
################

FROM docker.io/debian:bookworm AS export-stage

COPY --from=build-stage /opt/llvm/ /opt/llvm/

CMD ["echo", "This image is not meant to be run. It only provides files located in /opt/llvm."]
