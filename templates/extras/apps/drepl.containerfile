RUN dub fetch drepl
RUN {{ $dflags }} dub build --build=plain