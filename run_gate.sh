#!/bin/bash

# 抓取目前的絕對路徑
PROJ_ROOT=$(pwd)

# 1. 檢查參數
if [ -z "$1" ]; then
    echo "用法: sh run_gate.sh <TB檔名.v>"
    exit 1
fi

# 2. 取得名稱 (例如: lif_unit_tb)
BASE_NAME=$(basename "$1" _tb.v)
DIR_NAME="${BASE_NAME}_gate"

# 3. 建立並進入模擬子資料夾
TARGET_DIR="$PROJ_ROOT/sim/$DIR_NAME"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

echo "==== 正在執行模擬: $1 ===="

# 4. 執行模擬
# 注意：這裡我們依然使用絕對路徑讀取 filelist
xmverilog "$PROJ_ROOT/tb/$1" -f "$PROJ_ROOT/gate_filelist.f" +access+r

# 6. 回到根目錄
cd "$PROJ_ROOT"