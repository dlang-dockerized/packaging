## Install D Tools
COPY --from={{ $buildStage }} /opt/build/d-tools/generated/linux/64/ddemangle /usr/bin/ddemangle
COPY --from={{ $buildStage }} /opt/build/d-tools/generated/linux/64/dustmite /usr/bin/dustmite
COPY --from={{ $buildStage }} /opt/build/d-tools/generated/linux/64/rdmd /usr/bin/rdmd
