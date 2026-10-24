#!/bin/bash
# Port of make_berzerk_proms.bat for the Basys3 build. Run from this
# directory (the unzipped berzerk.zip) by contrib/tools/roms.sh, which sets:
#   MAKE_VHDL_PROM  path of the compiled make_vhdl_prom
#   PROM_DIR        output directory for the PROM VHDL
# make_vhdl_prom names the entity after its output argument, so it runs inside
# PROM_DIR with bare output file names.
# The .bat uses descriptive ROM names; the MAME berzerk.zip uses position names,
# read here directly: berzerk_rc31_1c.rom0.1c = 1c-0, ..._1d.rom1.1d = 1d-1,
# ..._3d.rom2.3d = 3d-2, ..._5d.rom3.5d = 5d-3, ..._6d.rom4.6d = 6d-4,
# ..._5c.rom5.5c = 5c-5, berzerk_r_vo_1c.1c = 1c, berzerk_r_vo_2c.2c = 2c.

set -euo pipefail

: "${MAKE_VHDL_PROM:?}" "${PROM_DIR:?}"
roms="$(pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat 1d-1 3d-2 5d-3 6d-4 5c-5 > "$tmp/prog2.bin"
cat 1c 2c > "$tmp/speech.bin"

cd "$PROM_DIR"
"$MAKE_VHDL_PROM" "$roms/1c-0"       berzerk_program1.vhd
"$MAKE_VHDL_PROM" "$tmp/prog2.bin"   berzerk_program2.vhd
"$MAKE_VHDL_PROM" "$tmp/speech.bin"  berzerk_speech_rom.vhd
