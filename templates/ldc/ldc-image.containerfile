{{< ldc/ldc-variables.php }}
###################
# imported images #
###################

FROM {{ $container_namespace }}/llvm:{{ $dependencies['llvm'] }}-{{ $base_image_alias }} AS llvm-imported
{{# if ($isBootstrappedByLDC): }}
	FROM {{ $container_namespace }}/ldc:{{ $dependencies['ldc'] }}-{{ $base_image_alias }} AS ldc-bootstrap-imported
{{# endif }}

###############
# build stage #
###############

{{< ldc/ldc-image-build-stage.containerfile }}

{{# if ($isBootstrappedByLDC): }}

	##################
	# self bootstrap #
	##################

	{{< ldc/ldc-image-build-stage.containerfile }}
{{# endif }}

{{< common/make-dub.containerfile }}

{{< common/make-d-tools.containerfile }}

################
# export stage #
################

{{# $buildStage = "build-stage-{$buildStageCounter}"; }}
FROM {{ $base_image }} AS export-stage

{{< common/prepare-runtime-environment.containerfile }}

COPY --from=llvm-imported /opt/llvm/bin /opt/llvm/bin

{{# if (in_array('clang', $llvmProjects)): }}
	RUN ln -s /opt/llvm/bin/clang /usr/local/bin/clang
	RUN ln -s /opt/llvm/bin/clang /usr/local/bin/clang++
	RUN ln -s /opt/llvm/bin/llc /usr/local/bin/llc
{{# endif }}

{{# if (in_array('lld', $llvmProjects)): }}
	{{# if ($dependenciesVersion['llvm']->getValue()->major >= 10): }}
		RUN ln -s /opt/llvm/bin/lld /usr/local/bin/ld
	{{# endif }}
	RUN ln -s /opt/llvm/bin/lld /usr/local/bin/ld.lld
	RUN ln -s /opt/llvm/bin/lld /usr/local/bin/lld
	RUN ln -s /opt/llvm/bin/lld /usr/local/bin/lld-link
{{# endif }}

{{# if (in_array('lldb', $llvmProjects)): }}
	COPY --from=llvm-imported /opt/llvm/lib/liblldb.so* /opt/llvm/lib/
	RUN ln -s /opt/llvm/bin/lldb /usr/local/bin/lldb
	RUN ln -s /opt/llvm/bin/lli /usr/local/bin/lli
{{# endif }}

COPY --from={{ $buildStage }} /opt/ldc /opt/ldc

RUN ln -s /opt/ldc/bin/ldc2 /usr/local/bin/ldc2
RUN ln -s /opt/ldc/bin/ldmd2 /usr/local/bin/ldmd2
RUN ln -s /opt/ldc/bin/ldmd2 /usr/local/bin/dmd
ENV DMD=/usr/local/bin/ldmd2

{{< d-tools/install-d-tools.containerfile }}

# Self-test
COPY ./resources/helloworld.d /opt/helloworld.d
RUN /opt/ldc/bin/ldmd2 -run /opt/helloworld.d
RUN rm /opt/helloworld.d

{{# if (isset($extras['dub'])): }}
	COPY --from={{ $buildStage }} /opt/build/dub/bin/dub /usr/local/bin/dub
{{# endif }}

{{< d-tools/install-d-tools.containerfile }}

COPY ./resources/scripts/entrypoint-ldc.sh /usr/local/bin/entrypoint

ENTRYPOINT [ "/usr/local/bin/entrypoint" ]
CMD [ "/usr/local/bin/ldc2" ]
