#### Install Emscripten SDK

##### Unpack SDK
RUN mkdir emsdk
RUN tar -xf emsdk.tar.gz -C emsdk --strip-components=1

{{< opend/emscripten/install-emsdk-dependencies.containerfile }}

##### Install SDK
RUN /opt/build/emsdk/emsdk install latest
RUN /opt/build/emsdk/emsdk activate latest

