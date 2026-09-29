# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="drastic-sa"
PKG_VERSION="260425_v2"
PKG_SHA256="70f2e69ae6e099463e050e11f22ce190b857d8d07e33ed31ae02196b059df638"
PKG_LICENSE="Proprietary:DRASTIC.pdf"
PKG_SITE="https://github.com/trngaje/advanced_drastic"
PKG_URL="${PKG_SITE}/releases/download/rocknix/advanced_drastic_rocknix_rgds_${PKG_VERSION}.tar.gz"
PKG_SOURCE_DIR="advanced_drastic"
PKG_ARCH="aarch64"
PKG_DEPENDS_TARGET="toolchain rocknix-hotkey"
PKG_LONGDESC="DraStic with the advanced_drastic hook library (layouts, themes, stylus, dual screen)"
PKG_TOOLCHAIN="manual"

if [ "${DEVICE}" = "S922X" ]; then
  PKG_DEPENDS_TARGET+=" libegl"
fi

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin
  chmod +x ${INSTALL}/usr/bin/start_drastic.sh

  mkdir -p ${INSTALL}/usr/config/drastic
  cp -rf ${PKG_BUILD}/* ${INSTALL}/usr/config/drastic/

  # Nintendo BIOS/firmware dumps are not redistributable: users provide their
  # own in /storage/roms/bios, DraStic's free replacement BIOS stays
  rm -f ${INSTALL}/usr/config/drastic/system/nds_bios_arm7.bin \
        ${INSTALL}/usr/config/drastic/system/nds_bios_arm9.bin \
        ${INSTALL}/usr/config/drastic/system/nds_firmware.bin
  # replaced by start_drastic.sh; show_hotkeys is a 32-bit ARM binary
  rm -f ${INSTALL}/usr/config/drastic/launch.sh \
        ${INSTALL}/usr/config/drastic/show_hotkeys

  # drastic.cf2 holds the file browser's last directory
  printf 'DSC2\002' > ${INSTALL}/usr/config/drastic/config/drastic.cf2
  truncate -s 16 ${INSTALL}/usr/config/drastic/config/drastic.cf2
  printf '/storage/roms/nds' >> ${INSTALL}/usr/config/drastic/config/drastic.cf2
  truncate -s 1044 ${INSTALL}/usr/config/drastic/config/drastic.cf2

  cp -rf ${PKG_DIR}/config/${DEVICE}/* ${INSTALL}/usr/config/drastic/config/
  cp -rf ${PKG_DIR}/config/drastic.gptk ${INSTALL}/usr/config/drastic/
  echo "${PKG_VERSION}" > ${INSTALL}/usr/config/drastic/.advdrastic_version
}

post_install() {
    case ${DEVICE} in
      RK3588)
        HOTKEY="export HOTKEY="guide""
      ;;
      *)
        HOTKEY=""
      ;;
    esac
    sed -e "s/@HOTKEY@/${HOTKEY}/g" \
        -i ${INSTALL}/usr/bin/start_drastic.sh
}
