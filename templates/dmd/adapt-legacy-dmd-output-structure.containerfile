### Adapt legacy output structure of DMD
RUN make -C dmd -f posix.mak install
RUN mkdir -p /opt/build/dmd/generated/linux/release/64
RUN mv /opt/install/linux/bin64/dmd /opt/build/dmd/generated/linux/release/64/dmd
