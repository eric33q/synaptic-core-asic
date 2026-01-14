wvResizeWindow -win $_nWave1 0 23 1920 1009
wvSetPosition -win $_nWave1 {("G1" 0)}
wvOpenFile -win $_nWave1 \
           {/home/t112830043/synaptic-core-asic/rtl/lif_neuron_for_local/spike_generator/spike_generator.fsdb}
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/lif_layer1_tb"
wvGetSignalSetScope -win $_nWave1 "/lif_layer1_tb/dut"
wvSetPosition -win $_nWave1 {("G1" 15)}
wvSetPosition -win $_nWave1 {("G1" 15)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/lif_layer1_tb/dut/busy} \
{/lif_layer1_tb/dut/clk} \
{/lif_layer1_tb/dut/cur_batch_cnt\[6:0\]} \
{/lif_layer1_tb/dut/finish} \
{/lif_layer1_tb/dut/next_state\[1:0\]} \
{/lif_layer1_tb/dut/pixel_data_in\[63:0\]} \
{/lif_layer1_tb/dut/req_addr\[6:0\]} \
{/lif_layer1_tb/dut/rst_n} \
{/lif_layer1_tb/dut/spike_data_out\[7:0\]} \
{/lif_layer1_tb/dut/spike_valid} \
{/lif_layer1_tb/dut/spikes_internal\[7:0\]} \
{/lif_layer1_tb/dut/sram_rdata\[95:0\]} \
{/lif_layer1_tb/dut/sram_wdata\[95:0\]} \
{/lif_layer1_tb/dut/start} \
{/lif_layer1_tb/dut/state\[1:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )} 
wvSetPosition -win $_nWave1 {("G1" 15)}
wvSetPosition -win $_nWave1 {("G1" 15)}
wvSetPosition -win $_nWave1 {("G1" 15)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/lif_layer1_tb/dut/busy} \
{/lif_layer1_tb/dut/clk} \
{/lif_layer1_tb/dut/cur_batch_cnt\[6:0\]} \
{/lif_layer1_tb/dut/finish} \
{/lif_layer1_tb/dut/next_state\[1:0\]} \
{/lif_layer1_tb/dut/pixel_data_in\[63:0\]} \
{/lif_layer1_tb/dut/req_addr\[6:0\]} \
{/lif_layer1_tb/dut/rst_n} \
{/lif_layer1_tb/dut/spike_data_out\[7:0\]} \
{/lif_layer1_tb/dut/spike_valid} \
{/lif_layer1_tb/dut/spikes_internal\[7:0\]} \
{/lif_layer1_tb/dut/sram_rdata\[95:0\]} \
{/lif_layer1_tb/dut/sram_wdata\[95:0\]} \
{/lif_layer1_tb/dut/start} \
{/lif_layer1_tb/dut/state\[1:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )} 
wvSetPosition -win $_nWave1 {("G1" 15)}
wvGetSignalClose -win $_nWave1
wvZoomAll -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 15 )} 
wvSelectSignal -win $_nWave1 {( "G1" 7 )} 
wvSetCursor -win $_nWave1 1804505.381304 -snap {("G2" 0)}
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 9 )} 
wvSelectSignal -win $_nWave1 {( "G1" 9 )} 
wvSetRadix -win $_nWave1 -format Bin
wvZoomIn -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 9 )} 
wvSetPosition -win $_nWave1 {("G1" 9)}
wvExpandBus -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 23)}
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 18 )} 
wvSelectSignal -win $_nWave1 {( "G1" 9 )} 
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvSetCursor -win $_nWave1 10363276.253075 -snap {("G1" 9)}
wvSetCursor -win $_nWave1 10340173.162669 -snap {("G1" 9)}
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomOut -win $_nWave1
wvSetCursor -win $_nWave1 4374185.116851 -snap {("G2" 0)}
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomAll -win $_nWave1
wvZoomAll -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvSetCursor -win $_nWave1 1328746.928042 -snap {("G1" 9)}
wvResizeWindow -win $_nWave1 0 23 1920 1009
wvSetCursor -win $_nWave1 1333043.221132
wvSetCursor -win $_nWave1 1339590.133244 -snap {("G1" 13)}
wvSetCursor -win $_nWave1 1380026.943346 -snap {("G1" 13)}
wvSetCursor -win $_nWave1 1426625.553082 -snap {("G1" 14)}
wvSetCursor -win $_nWave1 1497486.248880 -snap {("G1" 15)}
wvSetCursor -win $_nWave1 1298383.098187 -snap {("G1" 9)}
wvSetCursor -win $_nWave1 1328421.871406 -snap {("G1" 9)}
wvZoomIn -win $_nWave1
wvSetCursor -win $_nWave1 1336509.233426 -snap {("G1" 8)}
wvZoomAll -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSetCursor -win $_nWave1 5258677.121608 -snap {("G2" 0)}
wvSetCursor -win $_nWave1 5157915.158717 -snap {("G2" 0)}
wvSelectGroup -win $_nWave1 {G2}
wvSelectSignal -win $_nWave1 {( "G1" 3 )} 
wvSelectSignal -win $_nWave1 {( "G1" 3 )} 
wvSetRadix -win $_nWave1 -format UDec
wvSelectSignal -win $_nWave1 {( "G1" 21 )} 
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvSetCursor -win $_nWave1 14601153.034569 -snap {("G1" 7)}
wvSetCursor -win $_nWave1 14599196.491600 -snap {("G1" 4)}
wvSetCursor -win $_nWave1 9862098.843906 -snap {("G1" 21)}
wvSetCursor -win $_nWave1 9843854.080722 -snap {("G2" 0)}
wvSelectSignal -win $_nWave1 {( "G1" 20 )} 
wvSelectSignal -win $_nWave1 {( "G1" 23 )} 
wvSelectSignal -win $_nWave1 {( "G1" 12 )} 
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvResizeWindow -win $_nWave1 67 221 893 72
wvExit
