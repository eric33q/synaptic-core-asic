#!/bin/bash
PROJ_ROOT=$(pwd)
DIR_NAME=$(basename "$1" .v)
TARGET_DIR="$PROJ_ROOT/gate_sim/sim"
cd "$TARGET_DIR"
echo "==== SIMULATE: $1 ===="
xmverilog  -f "$PROJ_ROOT/gate_sim/script/gate_filelist.f" +define+SDF +access+r -nowarn CUVWSP

cd "$PROJ_ROOT"
