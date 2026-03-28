import numpy as np
import matplotlib.pyplot as plt
import os

def load_hex_to_array(filename):
    """讀取 Verilog 用的 hex 檔並轉為 784 維的一維陣列"""
    if not os.path.exists(filename):
        print(f"找不到參考圖片檔: {filename}")
        return None
    pixels = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            val_64bit = int(line, 16)
            for i in range(7, -1, -1): # 從 MSB 讀到 LSB
                pixels.append((val_64bit >> (i * 8)) & 0xFF)
    return np.array(pixels)

def calculate_cosine_similarity(vec1, vec2):
    """計算餘弦相似度"""
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    if norm1 == 0 or norm2 == 0: return 0.0
    return np.dot(vec1, vec2) / (norm1 * norm2)

# 設定輸入路徑
reference_hex_path = r"C:\Users\Mina Lin\Desktop\熱力圖\data\mnist_input_7.hex" 
reference_img = load_hex_to_array(reference_hex_path)

# 準備 2x3 的畫布 (寬12, 高7)
fig, axes = plt.subplots(2, 3, figsize=(12, 7))
axes = axes.flatten() # 將 2x2 矩陣攤平為一維陣列，方便用 index [0]~[5] 存取

# [第 1 格] 繪製原始圖片 (對照組)
if reference_img is not None:
    axes[0].imshow(reference_img.reshape(28, 28), cmap='gray', interpolation='nearest', vmin=0, vmax=255)
    axes[0].set_title('Input\n(Target)', fontsize=12, fontweight='bold')
axes[0].axis('off') # 隱藏 XY 座標軸

# [第 2~6 格] 依序繪製 Frame 5 ~ 25
frames_to_plot = [5, 10, 15, 20, 25] 
last_im = None 

for idx, frame in enumerate(frames_to_plot):
    ax_idx = idx + 1 # 從 axes[1] 開始畫
    filename = f"weights_frame_{frame}.txt"
    
    if not os.path.exists(filename):
        axes[ax_idx].set_title(f'Frame {frame}\nFile Not Found', fontsize=12)
        axes[ax_idx].axis('off')
        continue
        
    weights = []
    with open(filename, 'r') as f:
        for line in f.readlines():
            line = line.strip()
            if not line: continue
            val_64bit = int(line, 16)
            for i in range(7, -1, -1):
                weights.append((val_64bit >> (i * 8)) & 0xFF)
                
    weights_array = np.array(weights)
    
    # 計算相似度
    sim_score = 0.0
    if reference_img is not None:
        sim_score = calculate_cosine_similarity(reference_img, weights_array)
        
    # 畫出子圖
    last_im = axes[ax_idx].imshow(weights_array.reshape(28, 28), cmap='gray', interpolation='nearest', vmin=0, vmax=255)
    
    # 設定標題 (加上 Frame 數字與相似度)
    axes[ax_idx].set_title(f'Frame {frame}\nSim: {sim_score:.4f}', fontsize=12)
    axes[ax_idx].axis('off') # 隱藏座標軸讓畫面更乾淨

# 總體排版與輸出
plt.tight_layout()

if last_im is not None:
    fig.subplots_adjust(right=0.9)
    cbar_ax = fig.add_axes([0.92, 0.15, 0.02, 0.7])
    fig.colorbar(last_im, cax=cbar_ax, label='Synaptic Weight / Pixel Intensity (0~255)')

output_name = "STDP_Learning_Progression.png"
plt.savefig(output_name, dpi=300, bbox_inches='tight')
print(f"已生成 6 宮格漸進學習圖: {output_name}")

plt.show()