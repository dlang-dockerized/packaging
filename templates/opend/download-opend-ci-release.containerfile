## Download OpenD release bundle
RUN export opendArch=$(uname -m | sed 's/aarch64/arm64/') && \
	curl -fLsSo opend.tar.xz \
		"https://github.com/opendlang/opend/releases/download/CI/opend-latest-linux-${opendArch}.tar.xz"
