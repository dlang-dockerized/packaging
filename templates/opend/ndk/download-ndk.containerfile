## Download Android NDK
{{# if (!isset($NDK_VERSION)): }}
	!!! Error: $NDK_VERSION is not set !!!
{{# else: }}
	RUN curl -fLsSo ndk.zip \
		https://dl.google.com/android/repository/android-ndk-{{ $NDK_VERSION }}-linux.zip
{{# endif }}

