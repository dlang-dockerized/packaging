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

COPY ./templates/scripts/install-ldc-build-deps.sh .
RUN ./install-ldc-build-deps.sh

# Copy prebuilt LLVM from dlang-dockerized/llvm
COPY --from=llvm-imported /opt/llvm/ /opt/llvm/

{{# if (isset($LDC_BOOT_IMAGE)): }}
	# Copy prebuilt LDC from dlang-dockerized/ldc
	COPY --from=ldc-bootstrap-imported /opt/ldc/ /opt/ldc-bootstrap/
	RUN sed -i 's/\/opt\/ldc/\/opt\/ldc-bootstrap/g' /opt/ldc-bootstrap/etc/ldc2.conf
{{# endif }}

# Download, build and install LDC

ENV DL_LDC_TAG={{ $DL_LDC_TAG }}
ENV LDC_SEMVER_MAJOR={{ $LDC_SEMVER_MAJOR }}
ENV LDC_SEMVER_MINOR={{ $LDC_SEMVER_MINOR }}

COPY ./templates/scripts/download-ldc-source.sh .
RUN ./download-ldc-source.sh

COPY ./templates/scripts/build-ldc.sh .
{{# if (isset($LDC_BOOT_IMAGE)): }}
	RUN DMD=/opt/ldc-bootstrap/bin/ldmd2 ./build-ldc.sh
{{# else: }}
	RUN ./build-ldc.sh
{{# endif }}

# Self-test
COPY ./resources/helloworld.d /opt/helloworld.d
RUN /opt/ldc/bin/ldmd2 -run /opt/helloworld.d
RUN rm /opt/helloworld.d

{{# if (isset($DL_DUB_TAG)): }}
	# Download, build and install DUB
	ENV DL_DUB_TAG={{ $DL_DUB_TAG }}

	COPY ./templates/scripts/download-dub-source.sh .
	RUN ./download-dub-source.sh

	COPY ./templates/scripts/build-dub.sh .
	RUN DMD=/opt/ldc/bin/ldmd2 ./build-dub.sh
{{# endif }}

################
# export stage #
################

FROM {{ $BASE_IMAGE }} AS export-stage

{{# if (isset($LDC_BOOT_IMAGE)): }}
	ENV LDC_BOOT_IMAGE={{ $LDC_BOOT_IMAGE }}
{{# endif }}
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
