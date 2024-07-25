{{< dmd/dmd-variables.php }}
###################
# imported images #
###################

FROM {{ $container_namespace }}/ldc:{{ $dependencies['ldc'] }}-{{ $base_image_alias }} AS ldc-bootstrap-imported

###############
# build stage #
###############

FROM {{ $base_image }} AS build-stage

WORKDIR /opt/build

# Install dependencies

{{< common/install-common-system-tools.containerfile }}

# Copy prebuilt LDC from {{ $container_namespace }}/ldc
COPY --from=ldc-bootstrap-imported /opt/ldc/ /opt/ldc-bootstrap/
RUN sed -i 's/\/opt\/ldc/\/opt\/ldc-bootstrap/g' /opt/ldc-bootstrap/etc/ldc2.conf

# Download, build and install DMD

{{< dmd/download-dmd-source.containerfile }}
RUN ln -s /opt/ldc-bootstrap/bin/ldmd2 /usr/bin/dmd

{{< dmd/build-dmd.containerfile }}

{{< common/make-dub.containerfile }}

{{< common/make-d-tools.containerfile }}

################
# export stage #
################

FROM {{ $base_image }} AS export-stage

{{< common/prepare-runtime-environment.containerfile }}

COPY --from=build-stage /opt/build/dmd/generated/linux/release/64/dmd /usr/bin/dmd
COPY --from=build-stage /opt/build/phobos/generated/linux/release/64/* /usr/lib/
{{# if ($druntimeMonorepo): }}
    COPY --from=build-stage /opt/build/dmd/druntime/src /usr/include/dmd/druntime/import
{{# else: }}
    COPY --from=build-stage /opt/build/druntime/src /usr/include/dmd/druntime/import
{{# endif }}
COPY --from=build-stage /opt/build/phobos/std /usr/include/dmd/phobos/std
COPY --from=build-stage /opt/build/phobos/etc /usr/include/dmd/phobos/etc
{{# if (isset($DL_DUB_TAG)): }}
    COPY --from=build-stage /opt/build/dub/bin/dub /usr/bin/dub
{{# endif }}
COPY ./resources/dmd.conf /etc/dmd.conf
COPY ./templates/scripts/entrypoint-dmd.sh /usr/bin/entrypoint

# Install D Tools
COPY --from=build-stage /opt/build/d-tools/generated/linux/64/ddemangle /usr/bin/ddemangle
COPY --from=build-stage /opt/build/d-tools/generated/linux/64/dustmite /usr/bin/dustmite
COPY --from=build-stage /opt/build/d-tools/generated/linux/64/rdmd /usr/bin/rdmd

# Self-test
COPY ./resources/helloworld.d /opt/helloworld.d
RUN dmd -run /opt/helloworld.d
RUN rm /opt/helloworld.d

ENTRYPOINT [ "/usr/bin/entrypoint" ]
CMD [ "/usr/bin/dmd" ]
