wvResizeWindow -win $_nWave1 0 23 1920 1009
wvSetPosition -win $_nWave1 {("G1" 0)}
wvOpenFile -win $_nWave1 \
           {/home/t112830043/synaptic-core-asic/rtl/lif_neuron/lif_unit_64to1.fsdb}
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/lif_unit_64to1_tb"
wvGetSignalSetScope -win $_nWave1 "/lif_unit_64to1_tb/dut"
wvGetSignalSetScope -win $_nWave1 "/lif_unit_64to1_tb"
wvGetSignalSetScope -win $_nWave1 "/lif_unit_64to1_tb/dut"
wvSetPosition -win $_nWave1 {("G1" 18)}
wvSetPosition -win $_nWave1 {("G1" 18)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/lif_unit_64to1_tb/dut/V_mem\[14:0\]} \
{/lif_unit_64to1_tb/dut/V_mem_leak\[14:0\]} \
{/lif_unit_64to1_tb/dut/V_mem_next\[14:0\]} \
{/lif_unit_64to1_tb/dut/V_mem_out\[14:0\]} \
{/lif_unit_64to1_tb/dut/V_next_valid} \
{/lif_unit_64to1_tb/dut/clk} \
{/lif_unit_64to1_tb/dut/i_syn_accum\[14:0\]} \
{/lif_unit_64to1_tb/dut/i_syn_group\[14:0\]} \
{/lif_unit_64to1_tb/dut/i_syn_hold\[14:0\]} \
{/lif_unit_64to1_tb/dut/i_syn_to_int\[14:0\]} \
{/lif_unit_64to1_tb/dut/i_syn_valid} \
{/lif_unit_64to1_tb/dut/post_spike} \
{/lif_unit_64to1_tb/dut/ref_active} \
{/lif_unit_64to1_tb/dut/rst_n} \
{/lif_unit_64to1_tb/dut/state_next\[1:0\]} \
{/lif_unit_64to1_tb/dut/state_reg\[1:0\]} \
{/lif_unit_64to1_tb/dut/weight_flat\[63:0\]} \
{/lif_unit_64to1_tb/dut/weight_grp_cnt\[2:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 \
           18 )} 
wvSetPosition -win $_nWave1 {("G1" 18)}
wvSetPosition -win $_nWave1 {("G1" 18)}
wvSetPosition -win $_nWave1 {("G1" 18)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/lif_unit_64to1_tb/dut/V_mem\[14:0\]} \
{/lif_unit_64to1_tb/dut/V_mem_leak\[14:0\]} \
{/lif_unit_64to1_tb/dut/V_mem_next\[14:0\]} \
{/lif_unit_64to1_tb/dut/V_mem_out\[14:0\]} \
{/lif_unit_64to1_tb/dut/V_next_valid} \
{/lif_unit_64to1_tb/dut/clk} \
{/lif_unit_64to1_tb/dut/i_syn_accum\[14:0\]} \
{/lif_unit_64to1_tb/dut/i_syn_group\[14:0\]} \
{/lif_unit_64to1_tb/dut/i_syn_hold\[14:0\]} \
{/lif_unit_64to1_tb/dut/i_syn_to_int\[14:0\]} \
{/lif_unit_64to1_tb/dut/i_syn_valid} \
{/lif_unit_64to1_tb/dut/post_spike} \
{/lif_unit_64to1_tb/dut/ref_active} \
{/lif_unit_64to1_tb/dut/rst_n} \
{/lif_unit_64to1_tb/dut/state_next\[1:0\]} \
{/lif_unit_64to1_tb/dut/state_reg\[1:0\]} \
{/lif_unit_64to1_tb/dut/weight_flat\[63:0\]} \
{/lif_unit_64to1_tb/dut/weight_grp_cnt\[2:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 \
           18 )} 
wvSetPosition -win $_nWave1 {("G1" 18)}
wvGetSignalClose -win $_nWave1
wvSetCursor -win $_nWave1 43808.881434 -snap {("G2" 0)}
wvZoomAll -win $_nWave1
wvResizeWindow -win $_nWave1 431 578 960 332
wvResizeWindow -win $_nWave1 0 23 1920 1009
wvSetCursor -win $_nWave1 474006.026605 -snap {("G1" 18)}
wvSetCursor -win $_nWave1 492217.570850 -snap {("G1" 13)}
wvResizeWindow -win $_nWave1 867 114 960 332
wvResizeWindow -win $_nWave1 0 23 1920 1009
wvSaveSignal -win $_nWave1 \
           "/home/t112830043/synaptic-core-asic/rtl/lif_neuron/64to1_signal.rc"
wvResizeWindow -win $_nWave1 564 214 960 332
wvExit
