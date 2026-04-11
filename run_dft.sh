#!/bin/bash
# 1. 定義路徑變數
DFT_DIR="./dft"
SCRIPT_PATH="./dft/scripts/dc_dft.tcl"
SETUP_PATH="./dft/.synopsys_dc.setup"

# 2. 環境與資料夾檢查
if [ ! -d "$DFT_DIR" ]; then
    echo "錯誤: 找不到 $DFT_DIR 資料夾！"
    exit 1
fi

if [ ! -f "$SETUP_PATH" ]; then
    echo "錯誤: 找不到 $DFT_DIR/.synopsys_dc.setup！(請從 syn/ 複製一份過來)"
    exit 1
fi

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "錯誤: 找不到腳本 $SCRIPT_PATH！"
    exit 1
fi

# 建立輸出資料夾 (若不存在)
mkdir -p "$DFT_DIR/reports"
mkdir -p "$DFT_DIR/netlist"

# 3. 執行 DFT 合成
echo "Entering $DFT_DIR and running DFT insertion script..."
cd $DFT_DIR

# 啟動 DC 並將 log 輸出到 reports 資料夾
dc_shell -f ./scripts/dc_dft.tcl | tee ./reports/dft_exec.log

# 4. 回到根目錄
cd ..
echo "DFT Completed! Reports are in $DFT_DIR/reports, netlist is in $DFT_DIR/netlist."