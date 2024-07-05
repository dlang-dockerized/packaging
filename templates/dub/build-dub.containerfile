## Build DUB

### Unpack sources
RUN mkdir -p dub
RUN tar -xf dub.tar.gz -C dub --strip-components=1

### Build
WORKDIR /opt/build/dub
RUN DFLAGS="-O -inline" $DMD -run build.d
WORKDIR /opt/build

