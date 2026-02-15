#!/bin/bash

# 1. 定義路徑變數
SYN_DIR="./syn"
SCRIPT_PATH="./syn/scripts/dc_syn.tcl"
SETUP_PATH="./syn/.synopsys_dc.setup"

# 2. 環境檢查
if [ ! -d "$SYN_DIR" ]; then
    echo "錯誤: 找不到 $SYN_DIR 資料夾！"
    exit 1
fi

if [ ! -f "$SETUP_PATH" ]; then
    echo "錯誤: 找不到 $SYN_DIR/.synopsys_dc.setup！(請確保在 syn/ 下)"
    exit 1
fi

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "錯誤: 找不到腳本 $SCRIPT_PATH！"
    exit 1
fi

# 3. 執行合成
echo "正在進入 $SYN_DIR 並執行合成腳本..."
cd $SYN_DIR

# 執行指令調整：
# 這裡指向 scripts/dc_syn.tcl，但 DC 會在當前目錄 (syn/) 啟動並讀取 .setup
dc_shell -f ./scripts/dc_syn.tcl | tee ./reports/dc_exec.log

# 4. 回到根目錄
cd ..
echo "合成完畢！報表位於 $SYN_DIR/reports，網表位於 $SYN_DIR/netlist。"
