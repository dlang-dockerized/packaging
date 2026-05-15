{{< opend/ndk/install-ndk-install-dependencies.containerfile }}

## Install Android NDK
RUN unzip -d ndk.d ndk.zip
RUN mv ndk.d/android-ndk-*/ ndk

