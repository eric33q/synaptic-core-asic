import numpy as np
import matplotlib.pyplot as plt
import os

# ---------------------------------------------------------
# 設定要觀察的 Frame (我們挑選初、中、後期來觀察分佈演進)
# ---------------------------------------------------------
frames_to_plot = [5, 15, 25] 
fig, axes = plt.subplots(1, 3, figsize=(15, 5))

for idx, frame in enumerate(frames_to_plot):
    filename = f"weights_frame_{frame}.txt"
    
    if not os.path.exists(filename):
        axes[idx].set_title(f'Frame {frame} Not Found', fontsize=14)
        continue
        
    weights = []
    # 讀取 Verilog 匯出的 Hex 檔案並轉成 10 進位 (0~255)
    with open(filename, 'r') as f:
        for line in f.readlines():
            line = line.strip()
            if not line: continue
            val_64bit = int(line, 16)
            for i in range(7, -1, -1):
                weights.append((val_64bit >> (i * 8)) & 0xFF)
                
    weights_array = np.array(weights)
    
    # ---------------------------------------------------------
    # 繪製直方圖 (Histogram)
    # bins=50 代表將 0~255 切成 50 個區間來統計數量
    # ---------------------------------------------------------
    axes[idx].hist(weights_array, bins=50, range=(0, 255), color='royalblue', alpha=0.8, edgecolor='black')
    
    # 設定圖表標籤
    axes[idx].set_title(f'Frame {frame} Weight Distribution', fontsize=14, fontweight='bold')
    axes[idx].set_xlabel('Synaptic Weight Value (0 ~ 255)', fontsize=12)
    axes[idx].set_ylabel('Number of Synapses (Count)', fontsize=12)
    axes[idx].grid(axis='y', linestyle='--', alpha=0.7)
    
    # 固定 Y 軸的最高高度，讓三張圖的比例一致，方便比較
    axes[idx].set_ylim(0, 800) # 💡 若您的突觸總數(784)有改變，可調整此上限

# 整體排版與輸出
plt.tight_layout()
output_name = "STDP_Bimodal_Distribution.png"
plt.savefig(output_name, dpi=300, bbox_inches='tight')
print(f"🎉 成功生成雙峰分佈圖: {output_name}")

plt.show()