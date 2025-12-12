wvSetPosition -win $_nWave1 {("G1" 0)}
wvOpenFile -win $_nWave1 \
           {/home/t112830043/synaptic-core-asic/rtl/lif_neuron_for_local/one_to_one/one_to_one.fsdb}
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/one_to_one_tb"
wvGetSignalSetScope -win $_nWave1 "/one_to_one_tb/u_dut"
wvSetPosition -win $_nWave1 {("G1" 12)}
wvSetPosition -win $_nWave1 {("G1" 12)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/one_to_one_tb/u_dut/V_mem\[7:0\]} \
{/one_to_one_tb/u_dut/V_mem_leak\[7:0\]} \
{/one_to_one_tb/u_dut/V_mem_next\[7:0\]} \
{/one_to_one_tb/u_dut/V_mem_out\[7:0\]} \
{/one_to_one_tb/u_dut/V_next_valid} \
{/one_to_one_tb/u_dut/clk} \
{/one_to_one_tb/u_dut/i_syn\[7:0\]} \
{/one_to_one_tb/u_dut/post_spike} \
{/one_to_one_tb/u_dut/ref_active} \
{/one_to_one_tb/u_dut/rst_n} \
{/one_to_one_tb/u_dut/state_next\[1:0\]} \
{/one_to_one_tb/u_dut/state_reg\[1:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 1 2 3 4 5 6 7 8 9 10 11 12 )} 
wvSetPosition -win $_nWave1 {("G1" 12)}
wvSetPosition -win $_nWave1 {("G1" 12)}
wvSetPosition -win $_nWave1 {("G1" 12)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/one_to_one_tb/u_dut/V_mem\[7:0\]} \
{/one_to_one_tb/u_dut/V_mem_leak\[7:0\]} \
{/one_to_one_tb/u_dut/V_mem_next\[7:0\]} \
{/one_to_one_tb/u_dut/V_mem_out\[7:0\]} \
{/one_to_one_tb/u_dut/V_next_valid} \
{/one_to_one_tb/u_dut/clk} \
{/one_to_one_tb/u_dut/i_syn\[7:0\]} \
{/one_to_one_tb/u_dut/post_spike} \
{/one_to_one_tb/u_dut/ref_active} \
{/one_to_one_tb/u_dut/rst_n} \
{/one_to_one_tb/u_dut/state_next\[1:0\]} \
{/one_to_one_tb/u_dut/state_reg\[1:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 1 2 3 4 5 6 7 8 9 10 11 12 )} 
wvSetPosition -win $_nWave1 {("G1" 12)}
wvGetSignalClose -win $_nWave1
wvSetCursor -win $_nWave1 9801.848467 -snap {("G2" 0)}
wvZoomAll -win $_nWave1
wvSetCursor -win $_nWave1 116216.009254 -snap {("G2" 0)}
wvResizeWindow -win $_nWave1 643 160 893 202
wvResizeWindow -win $_nWave1 0 23 1920 1009
wvResizeWindow -win $_nWave1 660 205 893 202
