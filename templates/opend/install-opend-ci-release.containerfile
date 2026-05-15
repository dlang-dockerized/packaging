### Unpack OpenD release bundle
RUN mkdir -p opend
RUN tar -xf opend.tar.xz -C opend --strip-components=1
