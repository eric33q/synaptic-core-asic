import numpy as np
import matplotlib.pyplot as plt
import os
import matplotlib
matplotlib.use('Agg') # 支援遠端 Linux 執行

# =================================================================
# 💡 核心定義：讀取 Hex 與計算相似度
# =================================================================
def load_hex_to_array(filename):
    """讀取 Hex 檔案並轉為 NumPy 陣列 (0~255)"""
    if not os.path.exists(filename): 
        print(f"⚠️ 找不到檔案: {filename}")
        return None
    pixels = []
    try:
        with open(filename, 'r') as f:
            for line in f:
                line = line.strip()
                if not line: continue
                val = int(line, 16)
                for i in range(7, -1, -1):
                    pixels.append((val >> (i * 8)) & 0xFF)
        return np.array(pixels)
    except Exception as e:
        print(f"❌ 讀取 {filename} 發生錯誤: {e}")
        return None

def calculate_cosine_similarity(vec1, vec2):
    """計算兩個向量的餘弦相似度 (0~1)"""
    if vec1 is None or vec2 is None: return 0.0
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    return np.dot(vec1, vec2) / (norm1 * norm2) if norm1 > 0 and norm2 > 0 else 0.0

# =================================================================
# 🚀 執行邏輯
# =================================================================

# 1. 設定路徑與資料夾
TARGET_DIGIT = 7 # 我們要學的目標是 7
output_dir = "output/experiment_8_to_7" # 專屬實驗資料夾
if not os.path.exists(output_dir): os.makedirs(output_dir)

# 💡 指向您跑模擬的資料夾
sim_dir = "../sim/top_gate_tb" 
ref_path = "../data/mnist_input_7.hex" # 對照組是 7

# 2. 強制重設樣式為白底黑字
plt.rcParams.update(plt.rcParamsDefault)
ref_img = load_hex_to_array(ref_path)

# 3. 建立 6 宮格 (2x3)
fig, axes = plt.subplots(2, 3, figsize=(13, 7), facecolor='white')
axes = axes.flatten()

# 4. [第 1 格] 放目標圖片 7 (Target)
if ref_img is not None:
    axes[0].imshow(ref_img.reshape(28, 28), cmap='gray', vmin=0, vmax=255)
    axes[0].set_title(f'Target: {TARGET_DIGIT}', fontweight='bold', color='black')
axes[0].axis('off')

# 💡 5. 定義要觀察的 Frame (包含關鍵的 Frame 0)
# Frame 0 應該要是數字 8 的輪廓
frames_to_plot = [0, 5, 10, 15, 25] 
last_im = None

# 6. 迴圈讀取並繪製
for idx, f_num in enumerate(frames_to_plot):
    # 根據您的 tb 指令，確保檔名正確 (例如 weights_frame_0.txt)
    f_path = f"{sim_dir}/weights_frame_{f_num}.txt"
    w_arr = load_hex_to_array(f_path)
    
    # 計算與目標 "7" 的相似度
    score = calculate_cosine_similarity(ref_img, w_arr)
    
    # 找到對應的 Grid (跳過第 1 格)
    ax = axes[idx+1]
    
    if w_arr is not None:
        last_im = ax.imshow(w_arr.reshape(28, 28), cmap='gray', vmin=0, vmax=255)
        
        # 💡 特別標註 Frame 0
        title_prefix = "Initial (8)" if f_num == 0 else f"Frame {f_num}"
        ax.set_title(f'{title_prefix}\nSim to 7: {score:.4f}', color='black')
    else:
        ax.set_title(f'Frame {f_num}\n(Not Found)', color='red')
        
    ax.axis('off')

# 7. 排版與加上 Colorbar
plt.tight_layout(rect=[0, 0, 0.9, 1])
if last_im:
    # 加強 Colorbar 的標示
    cbar_ax = fig.add_axes([0.92, 0.15, 0.02, 0.7])
    cbar = fig.colorbar(last_im, cax=cbar_ax)
    cbar.set_label('Synaptic Weight (0~255)', color='black')
    cbar.ax.yaxis.set_tick_params(color='black')
    plt.setp(plt.getp(cbar.ax.axes, 'yticklabels'), color='black')

# 8. 儲存圖片
output_path = f"{output_dir}/transition_8_to_7.png"
plt.savefig(output_path, dpi=300, facecolor='white')
print(f"🎉 實驗圖片已產至: {output_path}")