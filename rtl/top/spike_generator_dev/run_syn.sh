#!/bin/bash
PRJ_ROOT=$(pwd)
SYN_DIR="${PRJ_ROOT}/syn"
SCRIPT_PATH="${SYN_DIR}/script/dc_syn.tcl"
SETUP_PATH="${SYN_DIR}/.synopsys_dc.setup"
if [ ! -d "$SYN_DIR" ]; then
    echo "Cannot find $SYN_DIR!"
    exit 1
fi

if [ ! -f "$SETUP_PATH" ]; then
    echo "Cannot find $SETUP_PATH!"
    exit 1
fi

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Cannot find $SCRIPT_PATH!"
    exit 1
fi

echo "Enter $SYN_DIR"
cd "$SYN_DIR" || exit 1
dc_shell -f "$SCRIPT_PATH" | tee report/dc_exec.log
cd - > /dev/null
echo "Finish synthesis! Report in $SYN_DIR/report, netlist in $SYN_DIR/netlist"