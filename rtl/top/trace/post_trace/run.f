// =======================================================
// Post-Synaptic Modules (Layer 2)
// =======================================================
// 1. LIF 神經元子模組 
../lif_neuron/lif_weight_adder.v
../lif_neuron/lif_leak.v
../lif_neuron/lif_integrator.v
../lif_neuron/lif_th_cmp.v
../lif_neuron/lif_refrac_ctrl.v 

// 2. LIF 神經元核心
../lif_neuron/lif_unit_784to1.v

// 3. Post-Trace 模組 
post_trace.v
trace_core.v

// 4. Post-Synaptic 頂層區塊
post_synaptic_block.v

// =======================================================
// Testbench 
// =======================================================
post_synaptic_block_tb.v