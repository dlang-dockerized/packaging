### Adapt legacy output structure of Phobos
RUN make -C phobos -f posix.mak install
COPY resources/dmd-dev-legacy.conf /opt/build/dmd/generated/linux/release/64/dmd.conf
RUN tree /opt/build/dmd/generated/linux/release/64/../../../../../druntime/import
RUN tree /opt/build/dmd/generated/linux/release/64/../../../../../phobos
#COPY --from=build-stage /opt/build/phobos/std /usr/include/dmd/phobos/std
#COPY --from=build-stage /opt/build/phobos/etc /usr/include/dmd/phobos/etc
