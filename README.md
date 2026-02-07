# Synaptic Core ASIC 模擬環境使用說明

本文件介紹如何使用自動化腳本進行 Spiking Neural Network (SNN) 核心電路的 RTL 模擬與波形分析。

## 1. 目錄結構架構
為了保持專案整潔，請務必按照以下結構存放檔案：

synaptic-core-asic/
├── run_rtl.sh           # 自動化模擬與啟動 Verdi 的主腳本
├── filelist.f           # 存放所有 RTL 電路檔案路徑的清單
├── rtl/                 # 存放電路原始碼 (.v)
│   └── lif_neuron/      # LIF 相關模組資料夾
├── tb/                  # 存放測試平台 (.v)
└── sim/                 # [自動生成] 存放模擬產生的 Log 與波形檔

##2. 環境設定
在使用前，請確保：
1.run_rtl.sh 具有執行權限：
chmod +x run_rtl.sh

2.filelist.f 已包含所有必要的 RTL 檔案路徑。

##3. 執行模擬流程
使用 run_rtl.sh 腳本可以一鍵完成：建立資料夾 -> 編譯模擬 -> 啟動 Verdi。

指令格式
./run_rtl.sh <測試檔名.v>
使用範例
若要測試全系統功能（假設測試檔為 tb/lif_unit_tb.v）：
./run_rtl.sh lif_unit_tb.v

##4. Testbench 撰寫規範 (波形傾倒)
請確保 $fsdbDumpfile 內的檔名與該測試平台的檔案名稱一致（例如：測試 xxx_tb.v 時，請命名為 xxx_tb.fsdb）。
initial begin
    $fsdbDumpfile("lif_unit_tb.fsdb"); 
    $fsdbDumpvars(0, lif_unit_tb);
    $fsdbDumpMDA;

end
