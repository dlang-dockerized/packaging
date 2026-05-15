## Install xpacks
RUN find /opt
RUN /opt/build/opend/bin/opend install xpack-emscripten
RUN /opt/build/opend/bin/opend install xpack-rpi
RUN /opt/build/opend/bin/opend install xpack-win64
RUN /opt/build/opend/bin/opend install xpack-zig

### Install xpack dependencies

{{< opend/emscripten/download-emsdk.containerfile }}
{{< opend/emscripten/install-emsdk.containerfile }}

{{< opend/zig/download-zig.containerfile }}
{{< opend/zig/install-zig.containerfile }}

