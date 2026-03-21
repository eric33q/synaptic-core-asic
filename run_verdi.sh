#!/bin/bash

# 抓取目前的絕對路徑
PROJ_ROOT=$(pwd)

# 1. 檢查參數
if [ -z "$1" ]; then
    echo "用法: sh run_verdi.sh <TB檔名.v>"
    exit 1
fi

# 2. 取得名稱 (例如: lif_unit_tb)
DIR_NAME=$(basename "$1" .v)
# 3. 建立並進入模擬子資料夾
TARGET_DIR="$PROJ_ROOT/sim/$DIR_NAME"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"
# 4. 檢查波形檔是否存在並自動開啟 Verdi
# 根據你的設定，檔名應該是 lif_unit_tb.fsdb
FSDB_NAME="${DIR_NAME}.fsdb"

if [ -f "$FSDB_NAME" ]; then
    echo "==== 模擬完成，正在啟動 Verdi 載入 $FSDB_NAME ===="
    # 這裡會同時載入原始碼與波形
    verdi "$PROJ_ROOT/tb/$1" -f "$PROJ_ROOT/rtl_filelist.f" -ssf "$FSDB_NAME" &
else
    echo "警告: 找不到波形檔 $FSDB_NAME，請檢查 TB 中的 \$fsdbDumpfile 設定。"
fi

# 5.  回到根目錄
cd "$PROJ_ROOT"
