import numpy as np
import matplotlib.pyplot as plt
import os

def load_hex_to_array(filename):
    if not os.path.exists(filename):
        print(f"⚠️ 找不到參考圖片檔: {filename}")
        return None
    pixels = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            val_64bit = int(line, 16)
            for i in range(7, -1, -1): 
                pixels.append((val_64bit >> (i * 8)) & 0xFF)
    return np.array(pixels)

def calculate_cosine_similarity(vec1, vec2):
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    if norm1 == 0 or norm2 == 0: return 0.0
    return np.dot(vec1, vec2) / (norm1 * norm2)

# =================================================================
# 💡 關鍵修改 1：對照組改為讀取數字 8 的 hex 檔
# =================================================================
# 請確認以下路徑與您電腦中的實際位置相符
reference_hex_path = r"../../data/mnist_input_8.hex" 
reference_img = load_hex_to_array(reference_hex_path)

fig, axes = plt.subplots(2, 3, figsize=(12, 7))
axes = axes.flatten() 

# [第 1 格] 繪製原始圖片 8 (對照組)
if reference_img is not None:
    axes[0].imshow(reference_img.reshape(28, 28), cmap='gray', interpolation='nearest', vmin=0, vmax=255)
    axes[0].set_title('Input 8\n(Target)', fontsize=12, fontweight='bold')
axes[0].axis('off') 

# =================================================================
# 💡 關鍵修改 2：讀取的檔案加上 _8.txt
# =================================================================
frames_to_plot = [5, 10, 15, 20, 25] 
last_im = None 

for idx, frame in enumerate(frames_to_plot):
    ax_idx = idx + 1 
    # 讀取剛剛 top_gate_tb_8.v 吐出來的檔案
    filename = f"weights_frame_{frame}_8.txt"
    
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
    
    sim_score = 0.0
    if reference_img is not None:
        sim_score = calculate_cosine_similarity(reference_img, weights_array)
        
    last_im = axes[ax_idx].imshow(weights_array.reshape(28, 28), cmap='gray', interpolation='nearest', vmin=0, vmax=255)
    axes[ax_idx].set_title(f'Frame {frame}\nSim: {sim_score:.4f}', fontsize=12)
    axes[ax_idx].axis('off') 

plt.tight_layout()

if last_im is not None:
    fig.subplots_adjust(right=0.9)
    cbar_ax = fig.add_axes([0.92, 0.15, 0.02, 0.7]) 
    fig.colorbar(last_im, cax=cbar_ax, label='Synaptic Weight / Pixel Intensity (0~255)')

# 💡 關鍵修改 3：輸出的圖片檔名也加上 _8
output_name = "STDP_Learning_Progression_8.png"
plt.savefig(output_name, dpi=300, bbox_inches='tight')
print(f"🎉 成功生成數字 8 的漸進學習圖: {output_name}")

plt.show()