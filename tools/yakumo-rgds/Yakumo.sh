#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)
#
# Yakumo (Monster Hunter Portable 3rd HD Ver.) on the Anbernic RG DS.
# Goes in /storage/roms/ports/ next to the yakumo/ folder made by build.sh.
#
# The game fills the upper screen (4:3, no black bars: Fill with Vert+), the
# lower one holds the on-screen controls. One window covers both panels, as
# DraStic does it: upper panel at 0,0, lower panel below it at 0,480.

. /etc/profile

PORT_DIR="$(dirname "$(readlink -f "$0")")/yakumo"
DATA_DIR="${YAKUMO_DATA_DIR:-${PORT_DIR}/data}"
LOG="${DATA_DIR}/yakumo.log"

# Panels and touch screen, as start_drastic.sh names them; overridable.
TOP_OUTPUT="${YAKUMO_TOP_OUTPUT:-DSI-2}"
BOTTOM_OUTPUT="${YAKUMO_BOTTOM_OUTPUT:-DSI-1}"
TOUCH_INPUT="${YAKUMO_TOUCH_INPUT:-1046:911:Goodix_Capacitive_TouchScreen}"
PANEL="${YAKUMO_PANEL:-640x480}"
PANEL_W="${PANEL%x*}"
PANEL_H="${PANEL#*x}"

set_kill set "-9 Yakumo"

mkdir -p "${DATA_DIR}"
# The RG DS defaults, on the first start only: the player's changes stay.
if [ ! -f "${DATA_DIR}/settings.ini" ]; then
  cp "${PORT_DIR}/settings.default.ini" "${DATA_DIR}/settings.ini"
fi

# First start with the disc image in the port folder: set the game up from
# it where it is, without the setup screens. Otherwise Yakumo's own setup
# asks for the image on screen.
if [ ! -f "${DATA_DIR}/EBOOT.ELF" ]; then
  for iso in "${PORT_DIR}"/*.iso; do
    [ -f "${iso}" ] || continue
    MHP3RD_DATA_DIR="${DATA_DIR}" LD_LIBRARY_PATH="${PORT_DIR}/lib" "${PORT_DIR}/Yakumo" --install "${iso}" --in-place \
      > "${DATA_DIR}/install.log" 2>&1
    break
  done
fi

{
  echo "== $(date) Yakumo on ${QUIRK_DEVICE:-unknown device}"
  swaymsg -t get_outputs 2>/dev/null | grep -E '"name"|"active"|"power"' || true
} > "${LOG}"

two_screens=false
if [ "${QUIRK_DEVICE}" = "Anbernic RG DS" ] && [ "${YAKUMO_SINGLE_SCREEN:-0}" != "1" ]; then
  two_screens=true
fi

restore_screens() {
  if ${two_screens}; then
    swaymsg "output ${BOTTOM_OUTPUT} power off" >/dev/null 2>&1
    swaymsg "input \"${TOUCH_INPUT}\" map_to_output ${TOP_OUTPUT}" >/dev/null 2>&1
    swaymsg "focus output ${TOP_OUTPUT}" >/dev/null 2>&1
  fi
}
trap restore_screens EXIT

if ${two_screens}; then
  export MHP3RD_SPLIT_SCREEN="${PANEL}"
  swaymsg "output ${TOP_OUTPUT} pos 0 0" >/dev/null
  swaymsg "output ${BOTTOM_OUTPUT} power on pos 0 ${PANEL_H}" >/dev/null
  swaymsg "for_window [app_id=\"yakumo\"] floating enable, border none, fullscreen disable, resize set ${PANEL_W} $((PANEL_H * 2)), move to output ${TOP_OUTPUT}, move absolute position 0 0" >/dev/null
  swaymsg "input \"${TOUCH_INPUT}\" map_to_output ${BOTTOM_OUTPUT}" >/dev/null
else
  swaymsg "for_window [app_id=\"yakumo\"] fullscreen enable" >/dev/null 2>&1
fi

# CPU and GPU to performance for the run; ROCKNIX puts them back afterwards.
performance 2>/dev/null || true

export SDL_APP_ID="yakumo"
export SDL_VIDEODRIVER="wayland"
# Touches drive the on-screen controls, not a pointer.
export SDL_TOUCH_MOUSE_EVENTS="0"
export MHP3RD_DATA_DIR="${DATA_DIR}"
export LD_LIBRARY_PATH="${PORT_DIR}/lib:${LD_LIBRARY_PATH}"
# A Vulkan driver other than the one gpudriver chose, if needed:
# YAKUMO_VK_ICD=/usr/share/vulkan/icd.d/panfrost_icd.aarch64.json
if [ -n "${YAKUMO_VK_ICD}" ]; then
  export VK_DRIVER_FILES="${YAKUMO_VK_ICD}"
fi

ulimit -s 65536 2>/dev/null || true
cd "${PORT_DIR}" || exit 1
./Yakumo "$@" >> "${LOG}" 2>&1
