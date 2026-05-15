###############
# build stage #
###############

FROM {{ $base_image }} AS build-stage

WORKDIR /opt/build

# Install dependencies
{{< common/install-common-system-tools.containerfile }}

# Download and install OpenD
{{< opend/download-opend-ci-release.containerfile }}
{{< opend/install-opend-ci-release.containerfile }}
{{< opend/install-opend-xpacks.containerfile }}

################
# export stage #
################

FROM {{ $base_image }} AS export-stage

{{< common/prepare-runtime-environment.containerfile }}
{{< opend/emscripten/install-emsdk-dependencies.containerfile }}

# Copy files
COPY --from=build-stage /opt/build/emsdk /opt/emsdk
COPY --from=build-stage /opt/build/opend /opt/opend
COPY --from=build-stage /opt/build/zig /opt/zig

# Symlink applications
RUN ln -s /opt/opend/bin/ddemangle /usr/local/bin/ddemangle
RUN ln -s /opt/opend/bin/dmd /usr/local/bin/dmd
RUN ln -s /opt/opend/bin/ldc2 /usr/local/bin/ldc2
RUN ln -s /opt/opend/bin/ldmd2 /usr/local/bin/ldmd2
RUN ln -s /opt/opend/bin/opend /usr/local/bin/opend
RUN ln -s /opt/opend/bin/timetrace2txt /usr/local/bin/timetrace2txt
RUN ln -s /opt/zig/zig /usr/local/bin/zig

COPY ./templates/scripts/entrypoint-opend.sh /usr/local/bin/entrypoint
COPY ./templates/scripts/zigcc.sh /usr/local/bin/zigcc

ENTRYPOINT [ "/usr/local/bin/entrypoint" ]
CMD [ "/usr/local/bin/opend" ]
