# mgbaqol-lr

[mGBA QoL](https://github.com/ddrsoul/mgbaqol): the mGBA core plus a live
Gen 3 Pokémon companion (party, battle, bag, region map, wild encounters) on
the second screen of dual-screen handhelds. Tested on the Anbernic RG DS.

This package installs:

- `/usr/lib/libretro/mgbaqol_libretro.so`, a symlink to the mgba core, and its
  `.info`, so EmulationStation offers `mgbaqol` as a Game Boy Advance core
  (`add_emu_core gba retroarch mgbaqol false` in `virtual/emulators`);
- the companion in `/usr/share/mgbaqol` and `/usr/bin/start_mgbaqol.sh`.

`runemu.sh` starts the companion only for the `mgbaqol` core: it enables
RetroArch's network commands in the append config and runs
`start_mgbaqol.sh` in the background.

To update, set `PKG_VERSION` to a newer
[release](https://github.com/ddrsoul/mgbaqol/releases) of ddrsoul/mgbaqol.
Usage, supported games and how it works are described there.
