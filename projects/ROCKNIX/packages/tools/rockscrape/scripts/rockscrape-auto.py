# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

# Run rockscrape for every system on the card, building the LaunchBox
# description index first for the systems that do not have it yet.

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rockscrape  # noqa: E402

CACHE_DIR = "/storage/.cache/rockscrape"


def main():
    systems = rockscrape.detect_systems(rockscrape.DEFAULT_ROMS)
    if not systems:
        rockscrape.log("no known system folders in %s" % rockscrape.DEFAULT_ROMS)
        return 2

    db = rockscrape.open_db(CACHE_DIR)
    missing = rockscrape.lb_missing_platforms(db, rockscrape.lb_platforms_for(systems))
    db.close()

    argv = ["--cache-dir", CACHE_DIR, "--systems", ",".join(systems)] + sys.argv[1:]
    if missing:
        rockscrape.log("building the description index for: %s\n" % ", ".join(missing))
        argv.append("--build-index")
    return rockscrape.main(argv)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
