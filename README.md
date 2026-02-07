```markdown
# Synaptic Core ASIC 模擬環境使用說明

本文件介紹如何使用自動化腳本進行 Spiking Neural Network (SNN) 核心電路的 RTL 模擬與波形分析。

---

## 1. 目錄結構架構

為了保持專案整潔，請務必按照以下結構存放檔案：

synaptic-core-asic/
├── run_rtl.sh           # 自動化模擬與啟動 Verdi 的主腳本
├── filelist.f           # 存放所有 RTL 電路檔案路徑的清單
├── rtl/                 # 存放電路原始碼 (.v)
│   └── lif_neuron/      # LIF 相關模組資料夾
├── tb/                  # 存放測試平台 (.v)
└── sim/                 # [自動生成] 存放模擬產生的 Log 與波形檔

```
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

```

---

### 如何在 VS Code 貼上以確保正確：
1. 回到 VS Code 的 `README.md`。
2. 按下 **`Ctrl + A`**（全選）並按 **`Delete`**（刪除），確保畫面全白。
3. 按下 **`Ctrl + Shift + V`** (在某些系統是貼上純文字) 或一般的 **`Ctrl + V`**。

如果你看到畫面出現了正確的文字，而沒有任何怪異的按鈕圖片，那就成功了！

**完成後，你可以在 VS Code 視窗右下角確認是否顯示為 "Markdown"。接下來需要我幫你把修正後的 `run_rtl.sh` 腳本也這樣噴一份給你嗎？**

```
