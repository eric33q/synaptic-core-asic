import numpy as np
import matplotlib.pyplot as plt
import os
import matplotlib
matplotlib.use('Agg')

# =================================================================
# 💡 關鍵：必須先定義這個函數，後面的程式碼才不會報錯
# =================================================================
def load_hex_to_array(filename):
    """讀取 Hex 檔案並轉為 NumPy 陣列"""
    if not os.path.exists(filename): 
        print(f"⚠️ 找不到檔案: {filename}")
        return None
    pixels = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            val = int(line, 16)
            for i in range(7, -1, -1):
                pixels.append((val >> (i * 8)) & 0xFF)
    return np.array(pixels)

def calculate_cosine_similarity(vec1, vec2):
    """計算兩個向量的相似度"""
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    return np.dot(vec1, vec2) / (norm1 * norm2) if norm1 > 0 and norm2 > 0 else 0.0

# =================================================================
# 接下來才是執行邏輯 (第 16 行之後)
# =================================================================
TARGET = 8
output_dir = f"output/mnist_{TARGET}"
if not os.path.exists(output_dir): os.makedirs(output_dir)

ref_path = f"../data/mnist_input_{TARGET}.hex"
sim_dir = "../sim/top_gate_tb_mnist8"

plt.rcParams.update(plt.rcParamsDefault)
ref_img = load_hex_to_array(ref_path) # 👈 現在 Python 就認識這個函數了！

fig, axes = plt.subplots(2, 3, figsize=(13, 7), facecolor='white')
axes = axes.flatten()

if ref_img is not None:
    axes[0].imshow(ref_img.reshape(28, 28), cmap='gray', vmin=0, vmax=255)
    axes[0].set_title(f'Target: {TARGET}', fontweight='bold', color='black')
axes[0].axis('off')

frames = [5, 10, 15, 20, 25]
last_im = None
for idx, f_num in enumerate(frames):
    f_path = f"{sim_dir}/weights_frame_{f_num}_mnist8.txt"
    w_arr = load_hex_to_array(f_path)
    ax = axes[idx+1]
    if w_arr is not None:
        score = calculate_cosine_similarity(ref_img, w_arr)
        last_im = ax.imshow(w_arr.reshape(28, 28), cmap='gray', vmin=0, vmax=255)
        ax.set_title(f'Frame {f_num}\nSim: {score:.4f}', color='black')
    ax.axis('off')

plt.tight_layout(rect=[0, 0, 0.9, 1])
if last_im:
    cbar_ax = fig.add_axes([0.92, 0.15, 0.02, 0.7])
    fig.colorbar(last_im, cax=cbar_ax, label='Weight (0~255)')

plt.savefig(f"{output_dir}/heatmap_{TARGET}.png", dpi=300, facecolor='white')
print(f"✅ 數字 {TARGET} 熱力圖已順利產出至 {output_dir}")