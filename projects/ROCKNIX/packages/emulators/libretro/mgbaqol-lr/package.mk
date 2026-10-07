# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="mgbaqol-lr"
PKG_VERSION="1367a4b38b68397fb58014674a56b7628a1c28a6" # v0.1.0
PKG_SHA256="b96dc9538f55f3c6493a15dedf6f35ee2394393343e525d9ac0901ff6f6331ba"
PKG_LICENSE="GPL-2.0-or-later"
PKG_SITE="https://github.com/ddrsoul/mgbaqol"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain mgba-lr Python3 SDL2 SDL2_ttf SDL2_gfx"
PKG_LONGDESC="mGBA QoL: the mGBA core plus a live Gen 3 Pokemon companion on the second screen."
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  # Same core under its own name, so ES can offer it per game and runemu.sh
  # knows when to start the companion (see the mgbaqol hook there).
  mkdir -p ${INSTALL}/usr/lib/libretro
  ln -sf mgba_libretro.so ${INSTALL}/usr/lib/libretro/mgbaqol_libretro.so
  cp ${PKG_BUILD}/rocknix/mgbaqol_libretro.info ${INSTALL}/usr/lib/libretro/

  mkdir -p ${INSTALL}/usr/share/mgbaqol
  cp ${PKG_BUILD}/companion/*.py ${INSTALL}/usr/share/mgbaqol/

  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_BUILD}/rocknix/start_mgbaqol.sh ${INSTALL}/usr/bin/
  chmod 0755 ${INSTALL}/usr/bin/start_mgbaqol.sh
}
