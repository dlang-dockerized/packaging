#### Install installation dependencies of Zig
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN apt-get -y install \
	minisign
RUN rm -rf /var/lib/apt/lists/*

