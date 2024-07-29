## Make extras

{{< d-tools/make-d-tools.containerfile }}

{{# $dflags = ($app_name === 'dmd') ? 'DFLAGS=\'-O -inline\'' : 'DFLAGS=\'-O2\''; }}
RUN mkdir /opt/extras
{{< extras/apps/drepl.containerfile }}
