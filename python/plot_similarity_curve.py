import numpy as np
import matplotlib.pyplot as plt
import os

# =================================================================
# 💡 1. 設定路徑 (請確保這兩個路徑正確)
# =================================================================
# 原始 MNIST 參考圖路徑
reference_hex_path = r"C:\Users\Mina Lin\Desktop\熱力圖\data\mnist_input_7.hex"
# 權重檔所在資料夾
weights_dir = r"./" # 假設您在 sim/top_tb/ 執行，或是改為絕對路徑

def load_hex_to_array(filename):
    if not os.path.exists(filename): return None
    pixels = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            val_64bit = int(line, 16)
            for i in range(7, -1, -1): # MSB to LSB
                pixels.append((val_64bit >> (i * 8)) & 0xFF)
    return np.array(pixels)

def calculate_cosine_similarity(vec1, vec2):
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    if norm1 == 0 or norm2 == 0: return 0.0
    return np.dot(vec1, vec2) / (norm1 * norm2)

# =================================================================
# 💡 2. 讀取並計算真實數據
# =================================================================
reference_img = load_hex_to_array(reference_hex_path)
frames = [5, 10, 15, 20, 25,30, 35] # 可以根據需要調整要讀取的 Frame 數字
real_similarities = []
valid_frames = []

print("🔄 正在讀取檔案並計算真實相似度...")
for f in frames:
    file_path = os.path.join(weights_dir, f"weights_frame_{f}.txt")
    weight_arr = load_hex_to_array(file_path)
    if weight_arr is not None and reference_img is not None:
        score = calculate_cosine_similarity(reference_img, weight_arr)
        real_similarities.append(score)
        valid_frames.append(f)
        print(f"   Frame {f:2d}: {score:.4f}")

# =================================================================
# 💡 3. 繪圖：黑底與一致性字體
# =================================================================
plt.style.use('dark_background')
fig, ax = plt.subplots(figsize=(10, 6))

# 統一字體設定 (標題與座標軸完全一樣)
# 使用相同的字體大小、顏色與粗細
font_style = {'fontsize': 16, 'fontweight': 'bold', 'color': 'white', 'family': 'sans-serif'}

# 繪製折線
line_color = '#00d4ff' # 亮藍色
ax.plot(valid_frames, real_similarities, marker='o', linestyle='-', 
        color=line_color, linewidth=3, markersize=10)

# 標註數字 (標註在點上方)
for i in range(len(valid_frames)):
    ax.text(valid_frames[i], real_similarities[i] + 0.005, f"{real_similarities[i]:.4f}", 
            color='white', fontsize=12, fontweight='bold', ha='center', va='bottom')

# 💡 【核心要求】：將主標題與 XY 軸標題設定為完全一致
ax.set_title('STDP Learning Convergence Curve', **font_style, pad=30)
ax.set_xlabel('Training Frames', **font_style, labelpad=15)
ax.set_ylabel('Cosine Similarity', **font_config if 'font_config' in locals() else font_style, labelpad=15)

# 微調座標軸
ax.set_xticks(valid_frames)
ax.tick_params(axis='both', which='major', labelsize=12, colors='white')
ax.grid(True, linestyle='--', color='gray', alpha=0.3)

# 讓邊框也是白色
for spine in ax.spines.values():
    spine.set_color('white')

plt.tight_layout()
plt.savefig("real_results_curve_dark.png", dpi=300)
plt.show()