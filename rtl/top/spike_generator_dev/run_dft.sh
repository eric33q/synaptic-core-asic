#!/bin/bash
DFT_DIR="./dft"
SCRIPT_PATH="./dft/script/dc_dft.tcl"
SETUP_PATH="./dft/.synopsys_dc.setup"
if [ ! -d "$DFT_DIR" ]; then
    echo "Cannot find $DFT_DIR!"
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

echo "Entering $DFT_DIR and running DFT insertion script..."
cd $DFT_DIR
dc_shell -f ./script/dc_dft.tcl | tee ./report/dft_exec.log

cd - > /dev/null
echo "DFT Completed! Reports are in $DFT_DIR/report, netlist is in $DFT_DIR/netlist."