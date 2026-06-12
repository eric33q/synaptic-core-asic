#!/bin/bash
PRJ_ROOT=$(pwd)
TMAX_DIR="${PRJ_ROOT}/dft/tmax"
SCRIPT_PATH="${TMAX_DIR}/script/tmax.tcl"
if [ ! -d "$TMAX_DIR" ]; then
    echo "Cannot find $TMAX_DIR!"
    exit 1
fi

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Cannot find $SCRIPT_PATH!"
    exit 1
fi
echo "Enter $TMAX_DIR"
cd "$TMAX_DIR" || exit 1
tmax -nogui -tcl "$SCRIPT_PATH"
cd - > /dev/null
echo "FINISH TMAX"