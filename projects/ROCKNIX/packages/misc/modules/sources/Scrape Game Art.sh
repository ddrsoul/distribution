#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

. /etc/profile

LOG_FILE="/var/log/rockscrape.log"

set_kill set "foot"

clear
echo "rockscrape: box art and descriptions for every system in /storage/roms"
echo "Existing gamelist.xml files are merged, a .backup copy is kept next to them."
echo "Hotkey + Start cancels."
echo

if ! curl -s -o /dev/null --max-time 10 "https://thumbnails.libretro.com/"; then
  echo "No internet connection: connect to Wi-Fi and try again."
  sleep 8
  exit 1
fi

# the first run (and a run with new systems) downloads the ~100 MB
# LaunchBox dump once to build the description index
/usr/bin/python3 /usr/lib/rockscrape/rockscrape-auto.py 2>&1 | tee "${LOG_FILE}"

echo
echo "Log: ${LOG_FILE}"
echo "Reloading the game lists..."
# reload once EmulationStation is back in front
nohup sh -c 'sleep 3; curl -s -o /dev/null "http://localhost:1234/reloadgames"' >/dev/null 2>&1 &
sleep 5
