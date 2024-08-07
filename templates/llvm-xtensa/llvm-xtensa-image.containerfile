<?php
	$LLVM_EXPERIMENTAL_TARGETS_TO_BUILD = "Xtensa"
?>

###############
# build stage #
###############

FROM {{ $base_image }} AS build-stage

WORKDIR /opt/build

# Install dependencies
{{< common/install-common-system-tools.containerfile }}
{{< llvm/install-llvm-build-deps.containerfile }}

# Download, build and install LLVM
{{< llvm-xtensa/download-llvm-xtensa-source.containerfile }}
{{< llvm/build-llvm.containerfile }}

################
# export stage #
################

FROM {{ $base_image }} AS export-stage

COPY --from=build-stage /opt/llvm/ /opt/llvm/

CMD ["echo", "This image is not meant to be run. It only provides files located in /opt/llvm."]
