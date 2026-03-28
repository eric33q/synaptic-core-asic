import numpy as np
import matplotlib.pyplot as plt
import os
import matplotlib
matplotlib.use('Agg')

# 💡 修改這裡即可切換數字：7 或 8
TARGET_DIGIT = 7 

if TARGET_DIGIT == 7:
    sim_subdir, suffix, ref_hex = "top_gate_tb", "", "mnist_input_7.hex"
else:
    sim_subdir, suffix, ref_hex = f"top_gate_tb_mnist{TARGET_DIGIT}", f"_mnist{TARGET_DIGIT}", f"mnist_input_{TARGET_DIGIT}.hex"

output_dir = f"output/mnist_{TARGET_DIGIT}"
if not os.path.exists(output_dir): os.makedirs(output_dir)

def load_hex_to_array(filename):
    if not os.path.exists(filename): return None
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
    norm1 = np.linalg.norm(vec1); norm2 = np.linalg.norm(vec2)
    return np.dot(vec1, vec2) / (norm1 * norm2) if norm1 > 0 and norm2 > 0 else 0.0

ref_img = load_hex_to_array(f"../data/{ref_hex}")
frames = [5, 10, 15, 20, 25, 30, 35]
scores, valid_f = [], []

for f in frames:
    f_path = f"../sim/{sim_subdir}/weights_frame_{f}{suffix}.txt"
    w_arr = load_hex_to_array(f_path)
    if w_arr is not None:
        scores.append(calculate_cosine_similarity(ref_img, w_arr))
        valid_f.append(f)

# 保持黑底風格，但確保標題字體與曲線清晰
plt.style.use('dark_background')
fig, ax = plt.subplots(figsize=(10, 6))
ax.plot(valid_f, scores, marker='o', color='#00d4ff', linewidth=3, markersize=10)

for i, txt in enumerate(scores):
    ax.annotate(f"{txt:.4f}", (valid_f[i], scores[i]), color='white', fontweight='bold', ha='center', xytext=(0,10), textcoords='offset points')

ax.set_title(f'STDP Learning Convergence (Digit {TARGET_DIGIT})', fontsize=16, fontweight='bold', pad=20)
ax.set_xlabel('Training Frames'); ax.set_ylabel('Cosine Similarity')
ax.grid(True, linestyle='--', alpha=0.3)

plt.tight_layout()
plt.savefig(f"{output_dir}/learning_curve_{TARGET_DIGIT}.png", dpi=300)
print(f"✅ 學習曲線已存至 {output_dir}")