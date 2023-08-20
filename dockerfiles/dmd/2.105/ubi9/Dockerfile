FROM docker.io/redhat/ubi9:latest AS builder

COPY ./scripts/install-system-tools.sh /opt/build/install-system-tools.sh
RUN /opt/build/install-system-tools.sh

COPY ./scripts/install-prebuilt-ldc.sh /opt/build/install-prebuilt-ldc.sh
RUN /opt/build/install-prebuilt-ldc.sh

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

FROM docker.io/redhat/ubi9:latest AS runtime
RUN dnf -y update && dnf -y install gcc make
COPY --from=builder /opt/build/dmd/generated/linux/release/64/dmd /usr/bin/dmd
COPY --from=builder /opt/build/phobos/generated/linux/release/64/* /usr/lib/
COPY --from=builder /opt/build/dmd/druntime/src /usr/include/dmd/druntime/import
COPY --from=builder /opt/build/phobos/std /usr/include/dmd/phobos/std
COPY --from=builder /opt/build/phobos/etc /usr/include/dmd/phobos/etc
COPY --from=builder /opt/build/dub/bin/dub /usr/bin/dub
COPY ./scripts/dmd.conf /etc/dmd.conf
COPY ./scripts/helloworld.d /opt/helloworld.d
COPY ./scripts/entrypoint-dmd.sh /usr/bin/entrypoint
# self-test
RUN dmd -run /opt/helloworld.d
ENTRYPOINT [ "/usr/bin/entrypoint" ]
CMD [ "/usr/bin/dmd" ]
