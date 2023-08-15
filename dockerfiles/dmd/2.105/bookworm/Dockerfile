FROM docker.io/debian:bookworm AS builder

COPY ./scripts/install-system-tools.sh /opt/build/install-system-tools.sh
RUN /opt/build/install-system-tools.sh

ENV DL_DMD_TAG v2.105.0
ENV DL_DUB_TAG v1.34.0

WORKDIR /opt/build

COPY ./scripts/download-dmd.sh /opt/build/download-dmd.sh
RUN ./download-dmd.sh

COPY ./scripts/download-dub.sh /opt/build/download-dub.sh
RUN ./download-dub.sh

COPY ./scripts/build-dmd.sh /opt/build/build-dmd.sh
RUN ./build-dmd.sh

COPY ./scripts/build-dub.sh /opt/build/build-dub.sh
RUN ./build-dub.sh

FROM docker.io/debian:bookworm AS runtime
RUN apt-get update && apt-get -y install build-essential
COPY --from=builder /opt/build/dub/bin/dub /usr/bin/dub
COPY --from=builder /opt/build/dmd/generated/linux/release/64/dmd /usr/bin/dmd
