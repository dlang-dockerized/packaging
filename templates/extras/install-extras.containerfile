### Install extras

{{< d-tools/install-d-tools.containerfile }}
COPY --from={{ $buildStage }} /opt/extras/* /usr/bin/
