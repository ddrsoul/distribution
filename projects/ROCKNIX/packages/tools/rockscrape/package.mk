# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="rockscrape"
PKG_VERSION="079f639492e615b31a09d83003ef4789f76ab927" # v1.0.0
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/ddrsoul/rockscrape"
PKG_URL="${PKG_SITE}.git"
GET_HANDLER_SUPPORT="git"
PKG_DEPENDS_TARGET="toolchain Python3"
PKG_LONGDESC="On-device box art and metadata scraper (libretro thumbnails + LaunchBox DB), no API keys"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/rockscrape
  cp -f ${PKG_BUILD}/rockscrape.py ${INSTALL}/usr/lib/rockscrape/
  cp -f ${PKG_DIR}/scripts/rockscrape-auto.py ${INSTALL}/usr/lib/rockscrape/

  mkdir -p ${INSTALL}/usr/bin
  cp -f ${PKG_DIR}/scripts/rockscrape ${INSTALL}/usr/bin/
  chmod 0755 ${INSTALL}/usr/bin/rockscrape
}
