###################
# imported images #
###################

FROM dlang/llvm:llvmorg-15.0-bookworm AS llvm-imported
FROM dlang/ldc:1.20-bookworm AS ldc-bootstrap-imported

###############
# build stage #
###############

FROM docker.io/debian:bookworm AS build-stage

WORKDIR /opt/build

# Install dependencies

COPY ./scripts/install-common-system-tools.sh .
RUN ./install-common-system-tools.sh

COPY ./scripts/install-ldc-build-deps.sh .
RUN ./install-ldc-build-deps.sh

# Copy prebuilt LLVM from dlang/llvm

COPY --from=llvm-imported /opt/llvm/ /opt/llvm/

# Copy prebuilt LDC from dlang/ldc

COPY --from=ldc-bootstrap-imported /opt/ldc/ /opt/ldc-bootstrap/
RUN sed -i 's/\/opt\/ldc/\/opt\/ldc-bootstrap/g' /opt/ldc-bootstrap/etc/ldc2.conf

# Download, build and install LCD

ENV DL_LDC_TAG v1.33.0
ENV LDC_SEMVER_MAJOR 1
ENV LDC_SEMVER_MINOR 33

COPY ./scripts/download-ldc-source.sh .
RUN ./download-ldc-source.sh

COPY ./scripts/build-ldc.sh .
RUN DMD=/opt/ldc-bootstrap/bin/ldmd2 ./build-ldc.sh

# Self-test
COPY ./resources/helloworld.d /opt/helloworld.d
RUN /opt/ldc/bin/ldmd2 -run /opt/helloworld.d
RUN rm /opt/helloworld.d

# Download, build and install DUB

ENV DL_DUB_TAG v1.34.0

COPY ./scripts/download-dub-source.sh .
RUN ./download-dub-source.sh

COPY ./scripts/build-dub.sh .
RUN DMD=/opt/ldc/bin/ldmd2 ./build-dub.sh

################
# export stage #
################

FROM docker.io/debian:bookworm AS export-stage

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && \
	apt-get -y install --no-install-recommends \
		build-essential && \
	rm -rf /var/lib/apt/lists/*

COPY --from=build-stage /opt/ldc /opt/ldc

# Self-test
COPY ./resources/helloworld.d /opt/helloworld.d
RUN /opt/ldc/bin/ldmd2 -run /opt/helloworld.d
RUN rm /opt/helloworld.d

COPY --from=build-stage /opt/build/dub/bin/dub /usr/bin/dub

COPY ./scripts/entrypoint-ldc.sh /usr/bin/entrypoint

ENTRYPOINT [ "/usr/bin/entrypoint" ]
CMD [ "/opt/ldc/bin/ldc2" ]
