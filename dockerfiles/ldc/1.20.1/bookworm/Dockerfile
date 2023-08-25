###################
# imported images #
###################

FROM dlang/llvm:llvmorg-10.0-bookworm AS llvm-imported
FROM dlang/ldc:lts-bookworm AS ldc-bootstrap-imported

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

ENV DL_LDC_TAG v1.20.1
ENV LDC_SEMVER_MAJOR 1
ENV LDC_SEMVER_MINOR 20

COPY ./scripts/download-ldc-source.sh .
RUN ./download-ldc-source.sh

COPY ./scripts/build-ldc.sh .
RUN DMD=/opt/ldc-bootstrap/bin/ldmd2 ./build-ldc.sh

# Self-test
COPY ./resources/helloworld.d /opt/helloworld.d
RUN /opt/ldc/bin/ldmd2 -run /opt/helloworld.d
RUN rm /opt/helloworld.d

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

COPY ./scripts/entrypoint-ldc.sh /usr/bin/entrypoint

ENTRYPOINT [ "/usr/bin/entrypoint" ]
CMD [ "/opt/ldc/bin/ldc2" ]
