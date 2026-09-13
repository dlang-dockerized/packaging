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
COPY --from=ldc-bootstrap-imported /opt/ldc/ /opt/ldc/
COPY --from=ldc-bootstrap-imported /opt/llvm/bin/lld /opt/llvm/bin/lld

RUN ln -s /opt/ldc/bin/ldmd2 /usr/local/bin/dmd
RUN ln -s /opt/llvm/bin/lld /usr/local/bin/ld
RUN ln -s /opt/llvm/bin/lld /usr/local/bin/ld.lld
RUN ln -s /opt/llvm/bin/lld /usr/local/bin/lld
RUN ln -s /opt/llvm/bin/lld /usr/local/bin/lld-link

# Download, build and install DMD

{{< dmd/download-dmd-source.containerfile }}

{{< dmd/build-dmd.containerfile }}

{{< common/make-dub.containerfile }}

{{< common/make-d-tools.containerfile }}

################
# export stage #
################

{{# $buildStage = 'build-stage'; }}
FROM {{ $base_image }} AS export-stage

{{< common/prepare-runtime-environment.containerfile }}

COPY --from=build-stage /opt/build/dmd/generated/linux/release/64/dmd /usr/local/bin/dmd
COPY --from=build-stage /opt/build/phobos/generated/linux/release/64/* /usr/lib/
{{# if ($druntimeMonorepo): }}
	COPY --from=build-stage /opt/build/dmd/druntime/src /usr/include/dmd/druntime/import
{{# else: }}
	COPY --from=build-stage /opt/build/druntime/src /usr/include/dmd/druntime/import
{{# endif }}
COPY --from=build-stage /opt/build/phobos/std /usr/include/dmd/phobos/std
COPY --from=build-stage /opt/build/phobos/etc /usr/include/dmd/phobos/etc
{{# if (isset($extras['dub'])): }}
	COPY --from=build-stage /opt/build/dub/bin/dub /usr/local/bin/dub
{{# endif }}
COPY ./resources/dmd.conf /etc/dmd.conf
COPY ./resources/scripts/entrypoint-dmd.sh /usr/local/bin/entrypoint

COPY --from=ldc-bootstrap-imported /opt/llvm/bin/lld /opt/llvm/bin/lld
RUN ln -s /opt/llvm/bin/lld /usr/local/bin/ld
RUN ln -s /opt/llvm/bin/lld /usr/local/bin/ld.lld
RUN ln -s /opt/llvm/bin/lld /usr/local/bin/lld
RUN ln -s /opt/llvm/bin/lld /usr/local/bin/lld-link

{{< d-tools/install-d-tools.containerfile }}

# Self-test
COPY ./resources/helloworld.d /opt/helloworld.d
RUN dmd -run /opt/helloworld.d
RUN rm /opt/helloworld.d

ENTRYPOINT [ "/usr/local/bin/entrypoint" ]
CMD [ "/usr/local/bin/dmd" ]
