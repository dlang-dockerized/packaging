###################
# imported images #
###################

FROM dlang-dockerized/{{ $LLVM_IMAGE }}-{{ $BASE_IMAGE_ALIAS }} AS llvm-imported
{{# if (isset($LDC_BOOT_IMAGE)): }}
	FROM dlang-dockerized/{{ $LDC_BOOT_IMAGE }}-{{ $BASE_IMAGE_ALIAS }} AS ldc-bootstrap-imported
{{# endif }}

###############
# build stage #
###############

FROM {{ $BASE_IMAGE }} AS build-stage

WORKDIR /opt/build

# Install dependencies

{{< common/install-common-system-tools.containerfile }}
{{< common/install-ldc-build-deps.containerfile }}

# Copy prebuilt LLVM from dlang-dockerized/llvm
COPY --from=llvm-imported /opt/llvm/ /opt/llvm/

{{# if (isset($LDC_BOOT_IMAGE)): }}
	# Copy prebuilt LDC from dlang-dockerized/ldc
	COPY --from=ldc-bootstrap-imported /opt/ldc/ /opt/ldc-bootstrap/
	RUN sed -i 's/\/opt\/ldc/\/opt\/ldc-bootstrap/g' /opt/ldc-bootstrap/etc/ldc2.conf
{{# endif }}

# Download, build and install LDC

{{< common/download-ldc-source.containerfile }}

{{# if (isset($LDC_BOOT_IMAGE)): }}
	ENV DMD=/opt/ldc-bootstrap/bin/ldmd2
{{# endif }}
{{< common/build-ldc.containerfile }}

# Self-test
COPY ./resources/helloworld.d /opt/helloworld.d
RUN /opt/ldc/bin/ldmd2 -run /opt/helloworld.d
RUN rm /opt/helloworld.d

{{# if (isset($DL_DUB_TAG)): }}
	# Download, build and install DUB
	{{< common/download-dub-source.containerfile }}
	{{< common/build-dub.containerfile }}
{{# endif }}

################
# export stage #
################

FROM {{ $BASE_IMAGE }} AS export-stage

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
