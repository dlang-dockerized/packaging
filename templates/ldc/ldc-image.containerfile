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

COPY --from={{ $buildStage }} /opt/ldc /opt/ldc

{{< d-tools/install-d-tools.containerfile }}

# Self-test
COPY ./resources/helloworld.d /opt/helloworld.d
RUN /opt/ldc/bin/ldmd2 -run /opt/helloworld.d
RUN rm /opt/helloworld.d

{{# if (isset($extras['dub'])): }}
	COPY --from={{ $buildStage }} /opt/build/dub/bin/dub /usr/bin/dub
{{# endif }}

{{< d-tools/install-d-tools.containerfile }}

COPY ./templates/scripts/entrypoint-ldc.sh /usr/bin/entrypoint

ENTRYPOINT [ "/usr/bin/entrypoint" ]
CMD [ "/opt/ldc/bin/ldc2" ]
