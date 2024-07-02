###############
# build stage #
###############

FROM docker.io/redhat/ubi9:latest AS build-stage

WORKDIR /opt/build

# Install dependencies

COPY ./templates/scripts/install-common-system-tools.sh .
RUN ./install-common-system-tools.sh

COPY ./templates/scripts/install-dmd-build-deps.sh .
RUN ./install-dmd-build-deps.sh

COPY ./templates/scripts/install-prebuilt-ldc.sh .
RUN ./install-prebuilt-ldc.sh # TODO: replace with /opt/ldc from dlang/ldc:latest-ubi9

# Download, build and install DMD

ENV DL_DMD_TAG v2.105.0

COPY ./templates/scripts/download-dmd-source.sh .
RUN ./download-dmd-source.sh

COPY ./templates/scripts/build-dmd.sh .
RUN ./build-dmd.sh

# Download, build and install DUB

ENV DL_DUB_TAG v1.34.0

COPY ./templates/scripts/download-dub-source.sh .
RUN ./download-dub-source.sh

COPY ./templates/scripts/build-dub.sh .
RUN DMD=/opt/build/dmd/generated/linux/release/64/dmd ./build-dub.sh

################
# export stage #
################

FROM docker.io/redhat/ubi9:latest AS export-stage

RUN dnf -y update && dnf -y install gcc make
COPY --from=build-stage /opt/build/dmd/generated/linux/release/64/dmd /usr/bin/dmd
COPY --from=build-stage /opt/build/phobos/generated/linux/release/64/* /usr/lib/
COPY --from=build-stage /opt/build/dmd/druntime/src /usr/include/dmd/druntime/import
COPY --from=build-stage /opt/build/phobos/std /usr/include/dmd/phobos/std
COPY --from=build-stage /opt/build/phobos/etc /usr/include/dmd/phobos/etc
COPY --from=build-stage /opt/build/dub/bin/dub /usr/bin/dub
COPY ./resources/dmd.conf /etc/dmd.conf
COPY ./resources/helloworld.d /opt/helloworld.d
COPY ./templates/scripts/entrypoint-dmd.sh /usr/bin/entrypoint

# Self-test
COPY ./resources/helloworld.d /opt/helloworld.d
RUN dmd -run /opt/helloworld.d
RUN rm /opt/helloworld.d

ENTRYPOINT [ "/usr/bin/entrypoint" ]
CMD [ "/usr/bin/dmd" ]
