#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)
#
# Builds Yakumo (Monster Hunter Portable 3rd HD Ver., recompiled) for the
# Anbernic RG DS. Runs inside the container from the Dockerfile next to it:
#
#   build.sh /iso/game.iso   the whole port, into /out/yakumo
#   build.sh --no-game       only checks that the patched program cross-builds
#                            (no game code: it cannot play, it cannot be copied)
#
# The recompiled code is generated from the player's own disc image, so the
# result must never be shared. /work keeps the sources, the build directories
# and ccache between runs; /out receives the port.
set -euo pipefail

YAKUMO_URL="${YAKUMO_URL:-https://github.com/TeamGDB/Yakumo.git}"
# The commit the patches were made against.
YAKUMO_REF="${YAKUMO_REF:-962d38b49383d0ab731e751c18da1f2547cdefb8}"
here="/opt/yakumo-rgds"
work="${WORK_DIR:-/work}"
out="${OUT_DIR:-/out}"
src="$work/Yakumo"
host_build="$work/build-host"
target_build="$work/build-aarch64"
data="$work/data"
SDL3_VERSION="3.2.30"
SDL3_SHA256="4c3b09330d866dc52eb65b66259a6684ad387252ca8c57901b3a2b534eb42e3d"
sdl3_install="$work/sdl3-aarch64"
# One generated unit needs about 4 GiB to compile; Yakumo's build limits
# itself to that, JOBS only bounds the rest.
jobs="${JOBS:-$(nproc)}"

export CCACHE_DIR="$work/ccache"

no_game=false
iso=""
case "${1:-}" in
    --no-game) no_game=true ;;
    "" | -h | --help)
        sed -n '5,14p' "$0"
        exit 2
        ;;
    *) iso="$1" ;;
esac
if ! $no_game && [[ ! -f "$iso" ]]; then
    echo "error: disc image $iso not found" >&2
    exit 1
fi

step() { echo; echo "==> $*"; }

step "Yakumo sources at $YAKUMO_REF"
if [[ ! -d "$src/.git" ]]; then
    git clone --quiet "$YAKUMO_URL" "$src"
fi
git -C "$src" fetch --quiet origin "$YAKUMO_REF" 2>/dev/null || git -C "$src" fetch --quiet origin
git -C "$src" -c advice.detachedHead=false checkout --quiet --force "$YAKUMO_REF"
git -C "$src" clean --quiet -fd -e profiles/mhp3rd/game -e profiles/mhp3rd/generated \
    -e profiles/mhp3rd/overlays -e profiles/mhp3rd/analysis
for patch in "$here"/patches/*.patch; do
    echo "applying $(basename "$patch")"
    git -C "$src" -c user.name=rocknix -c user.email=rocknix@localhost am --quiet --3way "$patch"
done

profile="$src/profiles/mhp3rd"

if ! $no_game; then
    step "Host tools (x86-64): installer, analyser, recompiler"
    cmake -S "$src" -B "$host_build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DPSPRECOMP_PROFILE=mhp3rd \
        -DMHP3RD_RENDERER=OFF -DMHP3RD_FFMPEG=OFF -DPSPRECOMP_BUILD_TESTS=OFF \
        -DPSPRECOMP_BUILD_PROFILE_TESTS=OFF > "$work/host-configure.log"
    cmake --build "$host_build" -j "$jobs" --target Yakumo psp_analyze psp_recomp

    step "Checking the disc image and preparing EBOOT.ELF"
    mkdir -p "$data"
    MHP3RD_DATA_DIR="$data" "$host_build/bin/Yakumo" --install "$iso" --in-place
    "$profile/scripts/prepare_game.sh" "$iso" "$data/EBOOT.ELF"

    step "Recompiling the executable"
    if ! compgen -G "$profile/generated/*.cpp" > /dev/null; then
        "$profile/scripts/generate.sh" "$host_build"
    else
        echo "generated code already present"
    fi

    step "Recompiling the code overlays"
    extract_dir="$profile/analysis/overlays"
    mkdir -p "$extract_dir"
    python3 "$profile/tools/databin.py" "$profile/game/disc.iso" extract-overlays "$extract_dir" > /dev/null
    total=0
    failed=0
    for image in "$extract_dir"/overlay_*.bin; do
        total=$((total + 1))
        stem="$(basename "$image" .bin)" # overlay_<BASE>_<name>
        rest="${stem#overlay_}"
        base="${rest%%_*}"
        name="${rest#*_}"
        compgen -G "$profile/overlays/ovl${base}_${name}_*/meta.txt" > /dev/null && continue
        if ! python3 "$profile/tools/add_overlay.py" --no-build "$host_build" "$image" "0x$base" > /dev/null 2>&1; then
            echo "failed: $name"
            failed=$((failed + 1))
        fi
    done
    echo "$total overlays, $failed failed"
    [[ $failed -eq 0 ]] || exit 1
fi

step "SDL3 $SDL3_VERSION for ROCKNIX (Wayland, libraries loaded at run time)"
if [[ ! -f "$sdl3_install/.version" || "$(cat "$sdl3_install/.version")" != "$SDL3_VERSION" ]]; then
    tarball="$work/SDL3-$SDL3_VERSION.tar.gz"
    [[ -f "$tarball" ]] || curl -fsSLo "$tarball" \
        "https://github.com/libsdl-org/SDL/releases/download/release-$SDL3_VERSION/SDL3-$SDL3_VERSION.tar.gz"
    echo "$SDL3_SHA256  $tarball" | sha256sum -c --quiet
    rm -rf "$work/SDL3-$SDL3_VERSION" "$work/sdl3-build" "$sdl3_install"
    tar -xzf "$tarball" -C "$work"
    cmake -S "$work/SDL3-$SDL3_VERSION" -B "$work/sdl3-build" -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE="$here/aarch64-linux-gnu.cmake" -DCMAKE_INSTALL_PREFIX="$sdl3_install" \
        -DSDL_SHARED=ON -DSDL_STATIC=OFF -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF -DSDL_DEPS_SHARED=ON \
        -DSDL_WAYLAND=ON -DSDL_WAYLAND_SHARED=ON -DSDL_WAYLAND_LIBDECOR=OFF -DSDL_X11=OFF \
        -DSDL_KMSDRM=ON -DSDL_KMSDRM_SHARED=ON -DSDL_VULKAN=ON -DSDL_OPENGL=OFF -DSDL_OPENGLES=ON \
        -DSDL_ALSA=ON -DSDL_ALSA_SHARED=ON -DSDL_PIPEWIRE=ON -DSDL_PIPEWIRE_SHARED=ON \
        -DSDL_PULSEAUDIO=OFF -DSDL_JACK=OFF -DSDL_SNDIO=OFF -DSDL_IBUS=OFF -DSDL_HIDAPI_LIBUSB=OFF \
        > "$work/sdl3-configure.log"
    cmake --build "$work/sdl3-build" -j "$jobs" > "$work/sdl3-build.log"
    cmake --install "$work/sdl3-build" > /dev/null
    echo "$SDL3_VERSION" > "$sdl3_install/.version"
fi

step "Cross-building for aarch64 (RG DS)"
cmake -S "$src" -B "$target_build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DPSPRECOMP_PROFILE=mhp3rd \
    -DCMAKE_TOOLCHAIN_FILE="$here/aarch64-linux-gnu.cmake" -DMHP3RD_RELEASE=ON \
    -DSDL3_DIR="$sdl3_install/lib/cmake/SDL3" \
    -DPSPRECOMP_BUILD_TESTS=OFF -DPSPRECOMP_BUILD_PROFILE_TESTS=OFF > "$work/target-configure.log"
grep -E "^-- (mhp3rd|psprecomp)" "$work/target-configure.log" || true
if ! grep -q "Vulkan renderer enabled" "$work/target-configure.log"; then
    echo "error: the renderer is not enabled for aarch64; see $work/target-configure.log" >&2
    exit 1
fi
cmake --build "$target_build" -j "$jobs"

step "Port folder"
port="$out/yakumo"
mkdir -p "$port/lib" "$port/overlays"
cp "$target_build/bin/Yakumo" "$port/"
aarch64-linux-gnu-strip "$port/Yakumo"
if compgen -G "$target_build/bin/overlays/*.so" > /dev/null; then
    cp "$target_build/bin/overlays/"*.so "$port/overlays/"
    aarch64-linux-gnu-strip "$port/overlays/"*.so
fi
cp -a "$target_build/bin/lib/." "$port/lib/" 2>/dev/null || true
# ROCKNIX has no SDL3: it goes with the port.
cp -L "$sdl3_install/lib/libSDL3.so.0" "$port/lib/"
aarch64-linux-gnu-strip "$port/lib/libSDL3.so.0"
[[ -d "$target_build/bin/fonts" ]] && cp -a "$target_build/bin/fonts" "$port/"
mkdir -p "$port/licenses"
cp "$src/LICENSE" "$port/licenses/Yakumo-LICENSE.txt"
cp "$profile/packaging/THIRD_PARTY_NOTICES.md" "$port/licenses/"
cp "$work/SDL3-$SDL3_VERSION/LICENSE.txt" "$port/licenses/SDL3-LICENSE.txt" 2>/dev/null || true
cp "$here/port/settings.ini" "$port/settings.default.ini"
cp "$here/port/Yakumo.sh" "$out/Yakumo.sh"
chmod +x "$out/Yakumo.sh" "$port/Yakumo"

# Nothing of the disc image goes into the port: only what was compiled.
if find "$port" -iname '*.iso' -o -iname 'EBOOT.*' -o -iname 'DATA.BIN' | grep -q .; then
    echo "error: game files found in $port" >&2
    exit 1
fi

file "$port/Yakumo"
echo
echo "Done: copy $out/Yakumo.sh and $out/yakumo/ to /storage/roms/ports/ on the RG DS."
if $no_game; then
    echo "(--no-game: this build has no game code and only shows that the port compiles.)"
fi
