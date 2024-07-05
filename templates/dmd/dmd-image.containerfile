###################
# imported images #
###################

FROM dlang-dockerized/{{ $LDC_BOOT_IMAGE }}-{{ $BASE_IMAGE_ALIAS }} AS ldc-bootstrap-imported

###############
# build stage #
###############

FROM {{ $BASE_IMAGE }} AS build-stage

WORKDIR /opt/build

# Install dependencies

{{< common/install-common-system-tools.containerfile }}

# Copy prebuilt LDC from dlang-dockerized/ldc
COPY --from=ldc-bootstrap-imported /opt/ldc/ /opt/ldc-bootstrap/
RUN sed -i 's/\/opt\/ldc/\/opt\/ldc-bootstrap/g' /opt/ldc-bootstrap/etc/ldc2.conf

# Download, build and install DMD

{{< dmd/download-dmd-source.containerfile }}
RUN ln -s /opt/ldc-bootstrap/bin/ldmd2 /usr/bin/dmd

{{< dmd/build-dmd.containerfile }}

{{< common/make-dub.containerfile }}

################
# export stage #
################

FROM {{ $BASE_IMAGE }} AS export-stage

{{< common/prepare-runtime-environment.containerfile }}

COPY --from=build-stage /opt/build/dmd/generated/linux/release/64/dmd /usr/bin/dmd
COPY --from=build-stage /opt/build/phobos/generated/linux/release/64/* /usr/lib/
COPY --from=build-stage /opt/build/dmd/druntime/src /usr/include/dmd/druntime/import
COPY --from=build-stage /opt/build/phobos/std /usr/include/dmd/phobos/std
COPY --from=build-stage /opt/build/phobos/etc /usr/include/dmd/phobos/etc
{{# if (isset($DL_DUB_TAG)): }}
    COPY --from=build-stage /opt/build/dub/bin/dub /usr/bin/dub
{{# endif }}
COPY ./resources/dmd.conf /etc/dmd.conf
COPY ./templates/scripts/entrypoint-dmd.sh /usr/bin/entrypoint

# Self-test
COPY ./resources/helloworld.d /opt/helloworld.d
RUN dmd -run /opt/helloworld.d
RUN rm /opt/helloworld.d

ENTRYPOINT [ "/usr/bin/entrypoint" ]
CMD [ "/usr/bin/dmd" ]
