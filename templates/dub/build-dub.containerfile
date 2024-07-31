## Build DUB

### Unpack sources
RUN mkdir -p dub
RUN tar -xf dub.tar.gz -C dub --strip-components=1

### Build
WORKDIR /opt/build/dub
{{# if ($app_name === 'dmd'): }}
	RUN DFLAGS="-O -inline" \
{{# else: }}
	RUN DFLAGS="-O2" \
{{# endif }}
	{{# if (!$extras['dub']->isSemanticTag()): }}
		$DMD -run build.d
	{{# elseif (($extras['dub']->semanticTag->major >= 2) || (($extras['dub']->semanticTag->major === 1) && ($extras['dub']->semanticTag->minor >= 20))): }}
		$DMD -run build.d
	{{# else: }}
		./build.sh
	{{# endif }}
WORKDIR /opt/build

