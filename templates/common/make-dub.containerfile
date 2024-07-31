## Make DUB

{{# if (isset($extras['dub'])): }}
	### Download, build and install DUB
	{{< dub/download-dub-source.containerfile }}
	{{< dub/build-dub.containerfile }}
{{# else: }}
	### -- Without DUB --
{{# endif }}

