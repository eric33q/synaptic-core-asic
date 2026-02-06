wvSetPosition -win $_nWave1 {("G1" 0)}
wvOpenFile -win $_nWave1 \
           {/home/t112830043/synaptic-core-asic/rtl/lif_neuron_for_local/spike_generator/layer1_buffer_wrapper.fsdb}
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/layer1_buffer_wrapper_tb"
wvSelectGroup -win $_nWave1 {G1}
wvSetCursor -win $_nWave1 466975.655488
wvSelectGroup -win $_nWave1 {G1}
wvSetPosition -win $_nWave1 {("G1" 7)}
wvSetPosition -win $_nWave1 {("G1" 7)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/layer1_buffer_wrapper_tb/L2_input_valid} \
{/layer1_buffer_wrapper_tb/L2_input_vector\[783:0\]} \
{/layer1_buffer_wrapper_tb/clk} \
{/layer1_buffer_wrapper_tb/l1_busy} \
{/layer1_buffer_wrapper_tb/l2_done_ack} \
{/layer1_buffer_wrapper_tb/pixel_data_in\[63:0\]} \
{/layer1_buffer_wrapper_tb/start} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 1 2 3 4 5 6 7 )} 
wvSetPosition -win $_nWave1 {("G1" 7)}
wvSetPosition -win $_nWave1 {("G1" 7)}
wvSetPosition -win $_nWave1 {("G1" 7)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/layer1_buffer_wrapper_tb/L2_input_valid} \
{/layer1_buffer_wrapper_tb/L2_input_vector\[783:0\]} \
{/layer1_buffer_wrapper_tb/clk} \
{/layer1_buffer_wrapper_tb/l1_busy} \
{/layer1_buffer_wrapper_tb/l2_done_ack} \
{/layer1_buffer_wrapper_tb/pixel_data_in\[63:0\]} \
{/layer1_buffer_wrapper_tb/start} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 1 2 3 4 5 6 7 )} 
wvSetPosition -win $_nWave1 {("G1" 7)}
wvGetSignalClose -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 2 )} 
wvZoomAll -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 4 )} 
wvSelectSignal -win $_nWave1 {( "G1" 3 )} 
wvZoom -win $_nWave1 362175.838415 624175.381098
wvSetPosition -win $_nWave1 {("G1" 3)}
wvSetPosition -win $_nWave1 {("G1" 1)}
wvSetPosition -win $_nWave1 {("G1" 0)}
wvMoveSelected -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 0)}
wvSetPosition -win $_nWave1 {("G1" 1)}
wvSelectSignal -win $_nWave1 {( "G1" 4 )} 
wvSetPosition -win $_nWave1 {("G1" 4)}
wvSetPosition -win $_nWave1 {("G1" 1)}
wvSetPosition -win $_nWave1 {("G1" 2)}
wvMoveSelected -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 2)}
wvSetPosition -win $_nWave1 {("G1" 3)}
wvSetPosition -win $_nWave1 {("G1" 1)}
wvMoveSelected -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 1)}
wvSetPosition -win $_nWave1 {("G1" 2)}
wvSelectSignal -win $_nWave1 {( "G1" 3 )} 
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSelectSignal -win $_nWave1 {( "G1" 4 )} 
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSelectSignal -win $_nWave1 {( "G1" 7 )} 
wvSetPosition -win $_nWave1 {("G1" 7)}
wvSetPosition -win $_nWave1 {("G1" 5)}
wvSetPosition -win $_nWave1 {("G1" 0)}
wvMoveSelected -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 0)}
wvSetPosition -win $_nWave1 {("G1" 1)}
wvSetCursor -win $_nWave1 431663.974028 -snap {("G1" 3)}
wvSelectSignal -win $_nWave1 {( "G1" 3 )} 
wvSearchNext -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 4 )} 
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSetCursor -win $_nWave1 2165821.182935 -snap {("G1" 6)}
wvSetCursor -win $_nWave1 2383807.997564 -snap {("G1" 3)}
wvSearchNext -win $_nWave1
wvSetCursor -win $_nWave1 3382661.136786 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 96652.270319 -snap {("G1" 2)}
wvSetCursor -win $_nWave1 104240.671708 -snap {("G1" 2)}
wvSetCursor -win $_nWave1 95853.491225 -snap {("G1" 2)}
wvResizeWindow -win $_nWave1 846 137 1073 699
wvResizeWindow -win $_nWave1 961 31 958 1048
wvResizeWindow -win $_nWave1 961 31 958 1048
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvResizeWindow -win $_nWave1 961 31 958 1048
wvSearchNext -win $_nWave1
wvSearchPrev -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 2 )} 
wvSetCursor -win $_nWave1 95546.384299 -snap {("G1" 2)}
wvSearchNext -win $_nWave1
wvSearchNext -win $_nWave1
wvSetCursor -win $_nWave1 97138.824038 -snap {("G1" 2)}
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/layer1_buffer_wrapper_tb"
wvGetSignalSetScope -win $_nWave1 "/layer1_buffer_wrapper_tb/u_dut"
wvGetSignalSetScope -win $_nWave1 "/layer1_buffer_wrapper_tb/u_dut/u_layer1"
wvGetSignalSetScope -win $_nWave1 \
           "/layer1_buffer_wrapper_tb/u_dut/u_layer1/lif_gen\[0\]"
wvGetSignalSetScope -win $_nWave1 \
           "/layer1_buffer_wrapper_tb/u_dut/u_layer1/lif_gen\[0\]/u_core"
wvGetSignalSetScope -win $_nWave1 "/layer1_buffer_wrapper_tb"
wvSetPosition -win $_nWave1 {("G1" 2)}
wvSetPosition -win $_nWave1 {("G1" 2)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/layer1_buffer_wrapper_tb/start} \
{/layer1_buffer_wrapper_tb/rst_n} \
{/layer1_buffer_wrapper_tb/clk} \
{/layer1_buffer_wrapper_tb/l1_busy} \
{/layer1_buffer_wrapper_tb/L2_input_valid} \
{/layer1_buffer_wrapper_tb/L2_input_vector\[783:0\]} \
{/layer1_buffer_wrapper_tb/l2_done_ack} \
{/layer1_buffer_wrapper_tb/pixel_data_in\[63:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 2 )} 
wvSetPosition -win $_nWave1 {("G1" 2)}
wvSetPosition -win $_nWave1 {("G1" 2)}
wvSetPosition -win $_nWave1 {("G1" 2)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/layer1_buffer_wrapper_tb/start} \
{/layer1_buffer_wrapper_tb/rst_n} \
{/layer1_buffer_wrapper_tb/clk} \
{/layer1_buffer_wrapper_tb/l1_busy} \
{/layer1_buffer_wrapper_tb/L2_input_valid} \
{/layer1_buffer_wrapper_tb/L2_input_vector\[783:0\]} \
{/layer1_buffer_wrapper_tb/l2_done_ack} \
{/layer1_buffer_wrapper_tb/pixel_data_in\[63:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 2 )} 
wvSetPosition -win $_nWave1 {("G1" 2)}
wvGetSignalClose -win $_nWave1
wvSelectGroup -win $_nWave1 {G2}
wvResizeWindow -win $_nWave1 0 23 1920 1057
wvSelectSignal -win $_nWave1 {( "G1" 1 )} 
wvResizeWindow -win $_nWave1 0 23 1920 1057
wvResizeWindow -win $_nWave1 0 23 1920 1057
wvSelectSignal -win $_nWave1 {( "G1" 1 )} 
wvSelectSignal -win $_nWave1 {( "G1" 2 )} 
wvResizeWindow -win $_nWave1 700 265 1073 699
wvResizeWindow -win $_nWave1 961 31 958 1048
wvSelectSignal -win $_nWave1 {( "G1" 4 )} 
wvSetCursor -win $_nWave1 105379.067763 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 114958.983014 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 125337.224536 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 134118.813516 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 146093.707580 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 155274.459696 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 164455.211812 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 175232.616469 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 186010.021127 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 194791.610107 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 207165.667306 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 215947.256287 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 225128.008402 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 235905.413060 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 246283.654582 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 255464.406698 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 265044.321949 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 276426.201885 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 285207.790866 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 296384.358659 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 307161.763316 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 316342.515432 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 326321.593818 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 336300.672205 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 347078.076863 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 357057.155249 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 367435.396771 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 376616.148887 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 384599.411596 -snap {("G1" 3)}
wvSetCursor -win $_nWave1 1375065.732955 -snap {("G1" 6)}
wvResizeWindow -win $_nWave1 961 31 958 1048
wvResizeWindow -win $_nWave1 961 31 958 1048
wvResizeWindow -win $_nWave1 961 31 958 1048
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSetPosition -win $_nWave1 {("G1" 6)}
wvExpandBus -win $_nWave1
wvScrollUp -win $_nWave1 28
wvScrollUp -win $_nWave1 63
wvScrollDown -win $_nWave1 22
wvScrollUp -win $_nWave1 674
wvSetCursor -win $_nWave1 1375848.137258
wvZoom -win $_nWave1 1374648.553638 1377447.582085
wvScrollUp -win $_nWave1 3
wvSetCursor -win $_nWave1 1375342.712692 -snap {("G1" 6)}
wvSetCursor -win $_nWave1 1375333.755801 -snap {("G1" 6)}
wvSetCursor -win $_nWave1 1376126.440657 -snap {("G1" 6)}
wvSetCursor -win $_nWave1 1375342.712692
wvScrollDown -win $_nWave1 1
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSetPosition -win $_nWave1 {("G1" 6)}
wvCollapseBus -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 6)}
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvExpandBus -win $_nWave1
wvScrollUp -win $_nWave1 746
wvScrollDown -win $_nWave1 13
wvScrollDown -win $_nWave1 516
wvSelectSignal -win $_nWave1 {( "G1" 559 )} 
wvSelectSignal -win $_nWave1 {( "G1" 560 )} 
wvSelectSignal -win $_nWave1 {( "G1" 559 )} 
wvSelectSignal -win $_nWave1 {( "G1" 560 )} 
wvSelectSignal -win $_nWave1 {( "G1" 559 )} 
wvSelectSignal -win $_nWave1 {( "G1" 560 )} 
wvSelectSignal -win $_nWave1 {( "G1" 559 )} 
wvSelectSignal -win $_nWave1 {( "G1" 560 )} 
wvScrollDown -win $_nWave1 7
wvSelectSignal -win $_nWave1 {( "G1" 559 )} 
wvSelectSignal -win $_nWave1 {( "G1" 560 )} 
wvScrollDown -win $_nWave1 0
wvSelectSignal -win $_nWave1 {( "G1" 559 )} 
wvSelectSignal -win $_nWave1 {( "G1" 560 )} 
wvSelectSignal -win $_nWave1 {( "G1" 559 )} 
wvSetCursor -win $_nWave1 1375577.831082 -snap {("G1" 564)}
wvSearchNext -win $_nWave1
wvSearchNext -win $_nWave1
wvSearchPrev -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 554 )} 
wvSelectSignal -win $_nWave1 {( "G1" 555 )} 
wvScrollUp -win $_nWave1 20
wvSelectSignal -win $_nWave1 {( "G1" 525 )} 
wvSetCursor -win $_nWave1 1424344.487259 -snap {("G1" 525)}
wvSelectSignal -win $_nWave1 {( "G1" 526 )} 
wvSelectSignal -win $_nWave1 {( "G1" 525 )} 
wvSelectSignal -win $_nWave1 {( "G1" 526 )} 
wvSelectSignal -win $_nWave1 {( "G1" 527 )} 
wvScrollUp -win $_nWave1 229
wvScrollUp -win $_nWave1 282
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSetPosition -win $_nWave1 {("G1" 6)}
wvCollapseBus -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 6)}
wvSelectSignal -win $_nWave1 {( "G1" 1 )} 
wvSelectSignal -win $_nWave1 {( "G1" 2 )} 
wvSelectSignal -win $_nWave1 {( "G1" 4 )} 
wvSearchNext -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvSetCursor -win $_nWave1 2389995.943831 -snap {("G1" 4)}
wvResizeWindow -win $_nWave1 961 31 958 1048
wvSetCursor -win $_nWave1 2397842.210916 -snap {("G1" 4)}
wvSetCursor -win $_nWave1 2401306.439096 -snap {("G1" 4)}
wvSetCursor -win $_nWave1 2401883.810459
wvResizeWindow -win $_nWave1 961 31 958 1048
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSelectSignal -win $_nWave1 {( "G1" 7 )} 
wvSetCursor -win $_nWave1 2169417.758675 -snap {("G1" 5)}
wvSetCursor -win $_nWave1 2178022.375235 -snap {("G1" 7)}
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvExpandBus -win $_nWave1
wvScrollUp -win $_nWave1 4
wvScrollUp -win $_nWave1 16
wvScrollUp -win $_nWave1 726
wvScrollDown -win $_nWave1 7
wvScrollUp -win $_nWave1 7
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSetPosition -win $_nWave1 {("G1" 6)}
wvCollapseBus -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 6)}
wvSetCursor -win $_nWave1 2167696.835363 -snap {("G1" 7)}
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvExpandBus -win $_nWave1
wvScrollDown -win $_nWave1 1
wvScrollUp -win $_nWave1 540
wvScrollUp -win $_nWave1 28
wvScrollUp -win $_nWave1 41
wvScrollUp -win $_nWave1 36
wvScrollDown -win $_nWave1 76
wvScrollDown -win $_nWave1 74
wvScrollDown -win $_nWave1 31
wvScrollDown -win $_nWave1 62
wvResizeWindow -win $_nWave1 961 31 958 1048
wvScrollDown -win $_nWave1 70
wvScrollDown -win $_nWave1 54
wvScrollDown -win $_nWave1 69
wvScrollDown -win $_nWave1 35
wvScrollDown -win $_nWave1 45
wvScrollDown -win $_nWave1 40
wvScrollUp -win $_nWave1 462
wvScrollUp -win $_nWave1 147
wvScrollUp -win $_nWave1 49
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSetPosition -win $_nWave1 {("G1" 6)}
wvCollapseBus -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 6)}
wvSetCursor -win $_nWave1 2167112.036727 -snap {("G1" 7)}
wvSetCursor -win $_nWave1 2172273.726902 -snap {("G1" 7)}
wvSelectSignal -win $_nWave1 {( "G1" 7 )} 
wvSetCursor -win $_nWave1 2166538.515597 -snap {("G1" 7)}
wvSetCursor -win $_nWave1 2174567.811424 -snap {("G1" 7)}
wvSetCursor -win $_nWave1 2389064.714238 -snap {("G1" 4)}
wvZoom -win $_nWave1 2113774.571589 2116068.656111
wvResizeWindow -win $_nWave1 837 68 1073 699
wvExit
