{{< opend/zig/install-zig-install-dependencies.containerfile }}

#### Download Zig
RUN curl -fLsSo zig.tar.xz \
	https://ziglang.org/download/{{ $extras['zig'] }}/zig-x86_64-linux-{{ $extras['zig'] }}.tar.xz
RUN curl -fLsSo zig.tar.xz.minisig \
	https://ziglang.org/download/{{ $extras['zig'] }}/zig-x86_64-linux-{{ $extras['zig'] }}.tar.xz.minisig
RUN minisign -Vm zig.tar.xz \
	-P 'RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U'

