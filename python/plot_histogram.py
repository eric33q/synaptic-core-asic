import numpy as np
import matplotlib.pyplot as plt
import os
import matplotlib
matplotlib.use('Agg')

def load_hex_to_array(filename):
    if not os.path.exists(filename): return None
    weights = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            val = int(line, 16)
            for i in range(7, -1, -1):
                weights.append((val >> (i * 8)) & 0xFF)
    return np.array(weights)

plt.rcParams.update(plt.rcParamsDefault)
output_dir = "output/mnist_7"
if not os.path.exists(output_dir): os.makedirs(output_dir)
sim_dir = "../sim/top_gate_tb"

frames = [5, 15, 25]
fig, axes = plt.subplots(1, 3, figsize=(15, 5), facecolor='white')

for idx, f_num in enumerate(frames):
    f_path = f"{sim_dir}/weights_frame_{f_num}.txt"
    w_arr = load_hex_to_array(f_path)
    if w_arr is not None:
        axes[idx].hist(w_arr, bins=50, range=(0, 255), color='royalblue', edgecolor='black', alpha=0.8)
        axes[idx].set_title(f'Frame {f_num} Distribution', fontweight='bold', color='black')
        axes[idx].set_ylim(0, 800)
        axes[idx].set_xlabel("Weight Value")
        axes[idx].set_ylabel("Count")

plt.tight_layout()
plt.savefig(f"{output_dir}/histogram.png", dpi=300, facecolor='white')
print(f"✅ 直方圖已存至 {output_dir}")