{{< ldc/ldc-variables.php }}
###################
# imported images #
###################

FROM dlang-dockerized/llvm:{{ $dependencies['llvm'] }}-{{ $base_image_alias }} AS llvm-imported
{{# if ($isBootstrappedByLDC): }}
	FROM dlang-dockerized/ldc:{{ $dependencies['ldc'] }}-{{ $base_image_alias }} AS ldc-bootstrap-imported
{{# endif }}

###############
# build stage #
###############

FROM {{ $base_image }} AS build-stage

WORKDIR /opt/build

# Install dependencies

{{< common/install-common-system-tools.containerfile }}
{{< ldc/install-ldc-build-deps.containerfile }}

# Copy prebuilt LLVM from dlang-dockerized/llvm
COPY --from=llvm-imported /opt/llvm/ /opt/llvm/

{{# if ($isBootstrappedByLDC): }}
	# Copy prebuilt LDC from dlang-dockerized/ldc
	COPY --from=ldc-bootstrap-imported /opt/ldc/ /opt/ldc-bootstrap/
	RUN sed -i 's/\/opt\/ldc/\/opt\/ldc-bootstrap/g' /opt/ldc-bootstrap/etc/ldc2.conf
{{# endif }}

# Download, build and install LDC

{{< ldc/download-ldc-source.containerfile }}

{{# if ($isBootstrappedByLDC): }}
	ENV DMD=/opt/ldc-bootstrap/bin/ldmd2
{{# endif }}
{{< ldc/build-ldc.containerfile }}

# Self-test
COPY ./resources/helloworld.d /opt/helloworld.d
RUN /opt/ldc/bin/ldmd2 -run /opt/helloworld.d
RUN rm /opt/helloworld.d

{{< common/make-dub.containerfile }}

################
# export stage #
################

FROM {{ $base_image }} AS export-stage

{{< common/prepare-runtime-environment.containerfile }}

COPY --from=build-stage /opt/ldc /opt/ldc

# Self-test
COPY ./resources/helloworld.d /opt/helloworld.d
RUN /opt/ldc/bin/ldmd2 -run /opt/helloworld.d
RUN rm /opt/helloworld.d

{{# if (isset($DL_DUB_TAG)): }}
	COPY --from=build-stage /opt/build/dub/bin/dub /usr/bin/dub
{{# endif }}

COPY ./templates/scripts/entrypoint-ldc.sh /usr/bin/entrypoint

ENTRYPOINT [ "/usr/bin/entrypoint" ]
CMD [ "/opt/ldc/bin/ldc2" ]
