<?php
	if (isset($buildStageCounter)) {
		++$buildStageCounter;
	} elseif ($isBootstrappedByLDC) {
		$buildStageCounter = 2;
	} else {
		$buildStageCounter = 1;
	}
?>
FROM {{ $base_image }} AS build-stage-{{ $buildStageCounter }}

WORKDIR /opt/build

# Install dependencies

{{< common/install-common-system-tools.containerfile }}
{{< ldc/install-ldc-build-deps.containerfile }}

# Copy prebuilt LLVM from {{ $container_namespace }}/llvm
COPY --from=llvm-imported /opt/llvm/ /opt/llvm/

# Download LDC sources

{{< ldc/download-ldc-source.containerfile }}

{{# if ($isBootstrappedByLDC): }}
	# Copy prebuilt LDC from {{ $container_namespace }}/ldc
	{{# if ($buildStageCounter <= 2): }}
		COPY --from=ldc-bootstrap-imported /opt/ldc/ /opt/ldc-bootstrap/
	{{# else: }}
		COPY --from=build-stage-{{ ($buildStageCounter - 1) }} /opt/ldc/ /opt/ldc-bootstrap/
	{{# endif }}
	RUN sed -i 's/\/opt\/ldc/\/opt\/ldc-bootstrap/g' /opt/ldc-bootstrap/etc/ldc2.conf
{{# endif }}

# Build and install LDC

{{# if ($isBootstrappedByLDC): }}
	ENV DMD=/opt/ldc-bootstrap/bin/ldmd2
{{# endif }}
{{< ldc/build-ldc.containerfile }}

# Self-test
COPY ./resources/helloworld.d /opt/helloworld.d
RUN /opt/ldc/bin/ldmd2 -run /opt/helloworld.d
RUN rm /opt/helloworld.d
