// Synaptic Core ASIC - RTL File List
// 使用相對於 syn/ 執行位置的路徑

// --- 1. Top Level ---
../rtl/top/top.v

// --- 2. Weight Memory System ---
// ../rtl/top/weight_memory/sram_sp_128x64.v
../rtl/top/weight_memory/sram_sp_128x64_rf.v
../rtl/top/weight_memory/spike_gen_mem.v
../rtl/top/weight_memory/pre_trace_mem.v

// --- 3. Layer 1: Spike Generator ---
../rtl/top/spike_generator/layer1_system_top.v
../rtl/top/spike_generator/spike_generator.v
../rtl/top/spike_generator/lif_unit_core.v
../rtl/top/spike_generator/layer1_lif_integrator.v
../rtl/top/spike_generator/layer1_lif_leak.v
../rtl/top/spike_generator/layer1_lif_th_cmp.v
../rtl/top/spike_generator/layer1_lif_refrac_logic.v
../rtl/top/spike_generator/spike_buffer_layer1.v

// --- 4. Layer 2: LIF Neuron ---
../rtl/top/lif_neuron/lif_integrator.v
../rtl/top/lif_neuron/lif_leak.v
../rtl/top/lif_neuron/lif_refrac_ctrl.v
../rtl/top/lif_neuron/lif_th_cmp.v
../rtl/top/lif_neuron/lif_unit_784to1.v
../rtl/top/lif_neuron/lif_weight_adder.v

// --- 5. Trace System ---
../rtl/top/trace/trace_core.v
../rtl/top/trace/pre_trace/pre_trace.v
../rtl/top/trace/pre_trace/pre_synaptic_block.v
../rtl/top/trace/post_trace/post_trace.v
../rtl/top/trace/post_trace/post_synaptic_block.v

// --- 6. STDP Learning Engine ---
../rtl/top/stdp/stdp.v