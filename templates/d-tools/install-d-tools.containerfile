## Install D Tools
COPY --from={{ $buildStage }} /opt/build/d-tools/generated/linux/64/ddemangle /usr/local/bin/ddemangle
COPY --from={{ $buildStage }} /opt/build/d-tools/generated/linux/64/dustmite /usr/local/bin/dustmite
COPY --from={{ $buildStage }} /opt/build/d-tools/generated/linux/64/rdmd /usr/local/bin/rdmd
