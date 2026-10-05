# Build environment for the Yakumo port to the Anbernic RG DS (ROCKNIX, aarch64).
#
# Debian 13 matches ROCKNIX's glibc (2.41). SDL3 is built by build.sh for
# Wayland only, everything else loaded at run time (ROCKNIX has no X11,
# PulseAudio or libdecor, which Debian's SDL3 links). The image holds
# only compilers and libraries; the game's disc image is mounted at run time
# and never ends up in the image (see build.sh).
FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture arm64 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential cmake ninja-build ccache git ca-certificates curl xz-utils \
      python3 pkg-config nasm glslang-tools file \
      g++-aarch64-linux-gnu gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu \
      libwayland-bin libvulkan-dev:arm64 \
      libwayland-dev:arm64 libxkbcommon-dev:arm64 libegl-dev:arm64 libdrm-dev:arm64 libgbm-dev:arm64 \
      libasound2-dev:arm64 libpipewire-0.3-dev:arm64 libudev-dev:arm64 libdbus-1-dev:arm64 \
 && rm -rf /var/lib/apt/lists/*

COPY aarch64-linux-gnu.cmake /opt/yakumo-rgds/aarch64-linux-gnu.cmake
COPY build.sh /opt/yakumo-rgds/build.sh
COPY patches/ /opt/yakumo-rgds/patches/
COPY Yakumo.sh settings.ini /opt/yakumo-rgds/port/

ENTRYPOINT ["/opt/yakumo-rgds/build.sh"]
