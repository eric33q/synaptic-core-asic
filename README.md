# Synaptic Core ASIC 模擬環境使用說明

本文件介紹如何使用自動化腳本進行 Spiking Neural Network (SNN) 核心電路的 RTL 模擬與波形分析。

---

## 1. 目錄結構架構

為了保持專案整潔，請務必按照以下結構存放檔案：
```text
synaptic-core-asic/
├── run_rtl.sh           # 自動化模擬與啟動 Verdi 的主腳本
├── filelist.f           # 存放所有 RTL 電路檔案路徑的清單
├── rtl/                 # 存放電路原始碼 (.v)
├── syn/                 # 存放合成相關檔案 
├── tb/                  # 存放測試平台 (.v)
└── sim/                 # [自動生成] 存放模擬產生的 Log 與波形檔

```

---
## 2. 環境設定

在使用前，請確保：

1. **腳本執行權限**：執行以下指令賦予腳本執行權限。
```bash
chmod +x run_rtl.sh

```


2. **檔案清單設定**：`filelist.f` 已包含所有必要的 RTL 檔案路徑（路徑需使用 `../../rtl/` 作為起始）。

---

## 3. 執行模擬流程

使用 `run_rtl.sh` 腳本可以一鍵完成：**建立資料夾 -> 編譯模擬 -> 啟動 Verdi**。

### 指令格式

```bash
./run_rtl.sh <測試檔名.v>

```

### 使用範例

若要測試全系統功能（假設測試檔為 `tb/lif_unit_tb.v`）：

```bash
./run_rtl.sh lif_unit_tb.v

```

---

## 4. Testbench 撰寫規範 (波形傾倒)

為了讓腳本能準確找到波形檔並自動開啟 Verdi，請在 Testbench 的 `initial` 區塊中使用與 **測試檔名相同** 的 `.fsdb` 檔名：

```verilog
initial begin
    // 檔名建議與 TB 檔案名稱對齊
    $fsdbDumpfile("lif_unit_tb.fsdb"); 
    $fsdbDumpvars(0, lif_unit_tb);
    $fsdbDumpMDA;
end

```
---

## 5. 邏輯綜合流程 (Synthesis)

在 RTL 模擬驗證無誤後，需將電路轉換為 Netlist。本專案採用 **TSMC 180nm (TSRI T180)** 製程進行綜合。

### 綜合目錄結構

```text
syn/
├── .synopsys_dc.setup   # TSRI T180 製程庫設定 (隱藏檔)
├── scripts/
│   └── dc_syn.tcl       # 合成核心腳本 (含分析、編譯與產出設定)
├── data/
│   └── TOP.sdc          # 時序約束 (設定 Clock 週期與 I/O 延遲)
├── netlist/             # [自動生成] 存放合成後的 .v 與 .sdf
└── reports/             # [自動生成] 存放面積 (Area) 與時序 (Timing) 報表

```

### 執行綜合指令

在根目錄下執行自動化合成腳本：

```bash
chmod +x run_syn.sh
./run_syn.sh

```

> **注意**：腳本會自動進入 `syn/` 目錄執行，並將執行日誌存於 `syn/reports/dc_exec.log` 以利除錯。

---

## 6. 時序與面積檢查

合成完成後，請務必檢查 `syn/reports/` 下的報表：

* **`timing.log`**：檢查 **Slack** 是否為正值。若出現 `VIOLATED`，需調整電路邏輯或放寬時序目標。
* **`area.log`**：查看總體面積與 Gate Count，這對於論文中評估硬體成本至關重要。



