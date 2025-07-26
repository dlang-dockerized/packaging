#### Build CMake
RUN mkdir -p cmake
RUN tar -xf cmake.tar.gz -C cmake --strip-components=1
WORKDIR /opt/build/cmake
RUN ./bootstrap
RUN make
RUN make install
WORKDIR /opt/build
