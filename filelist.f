// rtl 檔案清單
// lif
// 使用相對於執行位置 (sim/xxx/) 的路徑

// 1. System Verification
../../tb/top_tb.v

// 2. Top Level
../../rtl/top/top.v

// 3. Layer 1: Spike Generator

../../spike_generator_integrate/rtl/spike_generator/layer1_system_top.v
../../spike_generator_integrate/rtl/spike_generator/spike_generator.v
../../spike_generator_integrate/rtl/spike_generator/lif_unit_core.v
../../spike_generator_integrate/rtl/spike_generator/lif_integrator.v
../../spike_generator_integrate/rtl/spike_generator/lif_leak.v
../../spike_generator_integrate/rtl/spike_generator/lif_th_cmp.v
../../spike_generator_integrate/rtl/spike_generator/lif_refrac_logic.v 

// 4. LWeight Memory
../../rtl/weight_mem/we_uint_98X64.v
../../rtl/weight_mem/sram_sp_128x64.v
// 5. LIF Neuron 
../../rtl/lif_neuron/lif_integrator.v
../../rtl/lif_neuron/lif_leak.v
../../rtl/lif_neuron/lif_refrac_ctrl.v
../../rtl/lif_neuron/lif_th_cmp.v
../../rtl/lif_neuron/lif_unit_784to1.v
../../rtl/lif_neuron/lif_weight_adder.v

// 6. Post-Synaptic & Trace
../../rtl/trace/trace_core.v
../../rtl/trace/post_trace.v
../../rtl/trace/post_synaptic_block.v

// 7. STDP Engine 
../../rtl/stdp/stdp.v
