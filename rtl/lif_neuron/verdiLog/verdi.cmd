sidCmdLineBehaviorAnalysisOpt -incr -clockSkew 0 -loopUnroll 0 -bboxEmptyModule 0  -cellModel 0 -bboxIgnoreProtected 0 
debImport "-sv" "-f" "flist.f" "-top" "lif_unit_tb"
wvCreateWindow
wvSetPosition -win $_nWave2 {("G1" 0)}
wvOpenFile -win $_nWave2 \
           {/home/t112810019/synaptic_core/synaptic-core-asic/rtl/lif_neuron/lif_sim.fsdb}
wvSetFileTimeRange -win $_nWave2 -time_unit 1p 0 2785000
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb"
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/lif_unit_tb/dut/i_syn_accum\[17:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 1 )} 
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/lif_unit_tb/dut/i_syn_accum\[17:0\]} \
{/lif_unit_tb/dut/weight_grp_cnt\[6:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 2 )} 
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/lif_unit_tb/dut/i_syn_accum\[17:0\]} \
{/lif_unit_tb/dut/weight_grp_cnt\[6:0\]} \
{/lif_unit_tb/dut/V_mem\[18:0\]} \
{/lif_unit_tb/dut/V_mem_leak\[18:0\]} \
{/lif_unit_tb/dut/V_mem_next\[18:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 3 4 5 )} 
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/lif_unit_tb/dut/i_syn_accum\[17:0\]} \
{/lif_unit_tb/dut/weight_grp_cnt\[6:0\]} \
{/lif_unit_tb/dut/V_mem\[18:0\]} \
{/lif_unit_tb/dut/V_mem_leak\[18:0\]} \
{/lif_unit_tb/dut/V_mem_next\[18:0\]} \
{/lif_unit_tb/dut/post_spike} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 6 )} 
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/lif_unit_tb/dut/i_syn_accum\[17:0\]} \
{/lif_unit_tb/dut/weight_grp_cnt\[6:0\]} \
{/lif_unit_tb/dut/V_mem\[18:0\]} \
{/lif_unit_tb/dut/V_mem_leak\[18:0\]} \
{/lif_unit_tb/dut/V_mem_next\[18:0\]} \
{/lif_unit_tb/dut/post_spike} \
{/lif_unit_tb/dut/ref_active} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 7 )} 
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/lif_unit_tb/dut/i_syn_accum\[17:0\]} \
{/lif_unit_tb/dut/weight_grp_cnt\[6:0\]} \
{/lif_unit_tb/dut/V_mem\[18:0\]} \
{/lif_unit_tb/dut/V_mem_leak\[18:0\]} \
{/lif_unit_tb/dut/V_mem_next\[18:0\]} \
{/lif_unit_tb/dut/post_spike} \
{/lif_unit_tb/dut/ref_active} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 7 )} 
wvSetPosition -win $_nWave2 {("G1" 7)}
wvGetSignalClose -win $_nWave2
wvSelectSignal -win $_nWave2 {( "G1" 2 )} 
wvSelectSignal -win $_nWave2 {( "G1" 2 )} 
wvSetRadix -win $_nWave2 -format UDec
wvSelectSignal -win $_nWave2 {( "G1" 3 )} 
srcSetSearchPath \
           "/home/t112810019/synaptic_core/synaptic-core-asic/rtl/lif_neuron"
srcShowFile -file \
           /home/t112810019/synaptic_core/synaptic-core-asic/rtl/lif_neuron/lif_unit_784to1.v
wvSelectSignal -win $_nWave2 {( "G1" 1 )} 
wvSelectSignal -win $_nWave2 {( "G1" 1 )} 
wvSetRadix -win $_nWave2 -format UDec
wvSelectSignal -win $_nWave2 {( "G1" 5 )} 
wvSelectSignal -win $_nWave2 {( "G1" 5 )} 
wvSetRadix -win $_nWave2 -format UDec
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut"
wvSetPosition -win $_nWave2 {("G1" 8)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/lif_unit_tb/dut/i_syn_accum\[17:0\]} \
{/lif_unit_tb/dut/weight_grp_cnt\[6:0\]} \
{/lif_unit_tb/dut/V_mem\[18:0\]} \
{/lif_unit_tb/dut/V_mem_leak\[18:0\]} \
{/lif_unit_tb/dut/V_mem_next\[18:0\]} \
{/lif_unit_tb/dut/post_spike} \
{/lif_unit_tb/dut/ref_active} \
{/lif_unit_tb/dut/weight_mem\[63:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 8 )} 
wvSetPosition -win $_nWave2 {("G1" 8)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/lif_unit_tb/dut/i_syn_accum\[17:0\]} \
{/lif_unit_tb/dut/weight_grp_cnt\[6:0\]} \
{/lif_unit_tb/dut/V_mem\[18:0\]} \
{/lif_unit_tb/dut/V_mem_leak\[18:0\]} \
{/lif_unit_tb/dut/V_mem_next\[18:0\]} \
{/lif_unit_tb/dut/post_spike} \
{/lif_unit_tb/dut/ref_active} \
{/lif_unit_tb/dut/weight_mem\[63:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 8 )} 
wvSetPosition -win $_nWave2 {("G1" 8)}
wvGetSignalClose -win $_nWave2
wvSelectSignal -win $_nWave2 {( "G1" 8 )} 
wvSelectSignal -win $_nWave2 {( "G1" 8 )} 
wvSetRadix -win $_nWave2 -format Bin
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut"
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/lif_unit_tb/dut/i_syn_accum\[17:0\]} \
{/lif_unit_tb/dut/weight_grp_cnt\[6:0\]} \
{/lif_unit_tb/dut/V_mem\[18:0\]} \
{/lif_unit_tb/dut/V_mem_leak\[18:0\]} \
{/lif_unit_tb/dut/V_mem_next\[18:0\]} \
{/lif_unit_tb/dut/post_spike} \
{/lif_unit_tb/dut/ref_active} \
{/lif_unit_tb/dut/weight_mem\[63:0\]} \
{/lif_unit_tb/dut/rst_n} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 9 )} 
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/lif_unit_tb/dut/i_syn_accum\[17:0\]} \
{/lif_unit_tb/dut/weight_grp_cnt\[6:0\]} \
{/lif_unit_tb/dut/V_mem\[18:0\]} \
{/lif_unit_tb/dut/V_mem_leak\[18:0\]} \
{/lif_unit_tb/dut/V_mem_next\[18:0\]} \
{/lif_unit_tb/dut/post_spike} \
{/lif_unit_tb/dut/ref_active} \
{/lif_unit_tb/dut/weight_mem\[63:0\]} \
{/lif_unit_tb/dut/rst_n} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 9 )} 
wvSetPosition -win $_nWave2 {("G1" 9)}
wvGetSignalClose -win $_nWave2
wvSetCursor -win $_nWave2 1085898.778371 -snap {("G1" 6)}
wvSelectSignal -win $_nWave2 {( "G1" 3 )} 
wvSelectSignal -win $_nWave2 {( "G1" 3 )} 
wvSetRadix -win $_nWave2 -format UDec
wvSelectSignal -win $_nWave2 {( "G1" 6 )} 
wvSelectSignal -win $_nWave2 {( "G1" 7 )} 
wvSelectSignal -win $_nWave2 {( "G1" 6 )} 
srcShowFile -file \
           /home/t112810019/synaptic_core/synaptic-core-asic/rtl/lif_neuron/lif_th_cmp.v
wvDisplayGridCount -win $_nWave2 -off
wvGetSignalClose -win $_nWave2
wvReloadFile -win $_nWave2
wvDisplayGridCount -win $_nWave2 -off
wvGetSignalClose -win $_nWave2
wvReloadFile -win $_nWave2
wvDisplayGridCount -win $_nWave2 -off
wvGetSignalClose -win $_nWave2
wvReloadFile -win $_nWave2
wvSelectSignal -win $_nWave2 {( "G1" 4 )} 
wvSelectSignal -win $_nWave2 {( "G1" 4 )} 
wvSetRadix -win $_nWave2 -format UDec
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut/u_cmp"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut/u_leak"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut/u_ref"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut/u_w_adder/unpack_weight\[0\]"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut/u_w_adder/unpack_weight\[1\]"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut/u_w_adder"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut/u_ref"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut/u_w_adder"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut/u_ref"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut/u_leak"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut/u_cmp"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut/u_int"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut/u_cmp"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut/u_int"
wvGetSignalClose -win $_nWave2
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut/u_int"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut"
wvSetPosition -win $_nWave2 {("G1" 10)}
wvSetPosition -win $_nWave2 {("G1" 10)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/lif_unit_tb/dut/i_syn_accum\[17:0\]} \
{/lif_unit_tb/dut/weight_grp_cnt\[6:0\]} \
{/lif_unit_tb/dut/V_mem\[18:0\]} \
{/lif_unit_tb/dut/V_mem_leak\[18:0\]} \
{/lif_unit_tb/dut/V_mem_next\[18:0\]} \
{/lif_unit_tb/dut/post_spike} \
{/lif_unit_tb/dut/ref_active} \
{/lif_unit_tb/dut/weight_mem\[63:0\]} \
{/lif_unit_tb/dut/rst_n} \
{/lif_unit_tb/dut/state_next\[1:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 10 )} 
wvSetPosition -win $_nWave2 {("G1" 10)}
wvSetPosition -win $_nWave2 {("G1" 10)}
wvSetPosition -win $_nWave2 {("G1" 10)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/lif_unit_tb/dut/i_syn_accum\[17:0\]} \
{/lif_unit_tb/dut/weight_grp_cnt\[6:0\]} \
{/lif_unit_tb/dut/V_mem\[18:0\]} \
{/lif_unit_tb/dut/V_mem_leak\[18:0\]} \
{/lif_unit_tb/dut/V_mem_next\[18:0\]} \
{/lif_unit_tb/dut/post_spike} \
{/lif_unit_tb/dut/ref_active} \
{/lif_unit_tb/dut/weight_mem\[63:0\]} \
{/lif_unit_tb/dut/rst_n} \
{/lif_unit_tb/dut/state_next\[1:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 10 )} 
wvSetPosition -win $_nWave2 {("G1" 10)}
wvGetSignalClose -win $_nWave2
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G1" 9 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvZoom -win $_nWave2 1081825.194141 1088722.604102
wvZoom -win $_nWave2 1084806.143733 1085107.409915
wvZoom -win $_nWave2 1084994.752522 1085004.217590
wvZoom -win $_nWave2 1084999.488681 1085000.112433
wvZoom -win $_nWave2 1084999.973738 1085000.012819
wvSetCursor -win $_nWave2 1084999.989447 -snap {("G1" 5)}
wvSetCursor -win $_nWave2 1084999.989447 -snap {("G1" 5)}
wvZoom -win $_nWave2 1084999.978719 1085000.000941
wvSetCursor -win $_nWave2 1085000.053048 -snap {("G1" 5)}
wvSetCursor -win $_nWave2 1085000.279101 -snap {("G1" 5)}
wvSetCursor -win $_nWave2 1085000.040787
wvZoomAll -win $_nWave2
wvZoom -win $_nWave2 969948.275862 1103585.593870
wvDisplayGridCount -win $_nWave2 -off
wvGetSignalClose -win $_nWave2
wvReloadFile -win $_nWave2
wvZoomOut -win $_nWave2
wvDisplayGridCount -win $_nWave2 -off
wvGetSignalClose -win $_nWave2
wvReloadFile -win $_nWave2
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut"
wvSetPosition -win $_nWave2 {("G1" 10)}
wvSetPosition -win $_nWave2 {("G1" 10)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/lif_unit_tb/dut/i_syn_accum\[17:0\]} \
{/lif_unit_tb/dut/weight_grp_cnt\[6:0\]} \
{/lif_unit_tb/dut/V_mem\[18:0\]} \
{/lif_unit_tb/dut/V_mem_leak\[18:0\]} \
{/lif_unit_tb/dut/V_mem_next\[18:0\]} \
{/lif_unit_tb/dut/post_spike} \
{/lif_unit_tb/dut/ref_active} \
{/lif_unit_tb/dut/weight_mem\[63:0\]} \
{/lif_unit_tb/dut/state_next\[1:0\]} \
{/lif_unit_tb/dut/i_syn_group\[17:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 10 )} 
wvSetPosition -win $_nWave2 {("G1" 10)}
wvSetPosition -win $_nWave2 {("G1" 10)}
wvSetPosition -win $_nWave2 {("G1" 10)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/lif_unit_tb/dut/i_syn_accum\[17:0\]} \
{/lif_unit_tb/dut/weight_grp_cnt\[6:0\]} \
{/lif_unit_tb/dut/V_mem\[18:0\]} \
{/lif_unit_tb/dut/V_mem_leak\[18:0\]} \
{/lif_unit_tb/dut/V_mem_next\[18:0\]} \
{/lif_unit_tb/dut/post_spike} \
{/lif_unit_tb/dut/ref_active} \
{/lif_unit_tb/dut/weight_mem\[63:0\]} \
{/lif_unit_tb/dut/state_next\[1:0\]} \
{/lif_unit_tb/dut/i_syn_group\[17:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 10 )} 
wvSetPosition -win $_nWave2 {("G1" 10)}
wvGetSignalClose -win $_nWave2
wvSetActiveFile -win $_nWave2 -applyAnnotation off \
           {/home/t112810019/synaptic_core/synaptic-core-asic/rtl/lif_neuron/lif_sim.fsdb}
wvSetCursor -win $_nWave2 124574.335256
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut/u_int"
wvGetSignalSetScope -win $_nWave2 "/lif_unit_tb/dut"
wvSetPosition -win $_nWave2 {("G1" 11)}
wvSetPosition -win $_nWave2 {("G1" 11)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/lif_unit_tb/dut/i_syn_accum\[17:0\]} \
{/lif_unit_tb/dut/weight_grp_cnt\[6:0\]} \
{/lif_unit_tb/dut/V_mem\[18:0\]} \
{/lif_unit_tb/dut/V_mem_leak\[18:0\]} \
{/lif_unit_tb/dut/V_mem_next\[18:0\]} \
{/lif_unit_tb/dut/post_spike} \
{/lif_unit_tb/dut/ref_active} \
{/lif_unit_tb/dut/weight_mem\[63:0\]} \
{/lif_unit_tb/dut/state_next\[1:0\]} \
{/lif_unit_tb/dut/i_syn_group\[17:0\]} \
{/lif_unit_tb/dut/i_syn_hold\[17:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 11 )} 
wvSetPosition -win $_nWave2 {("G1" 11)}
wvSetPosition -win $_nWave2 {("G1" 11)}
wvSetPosition -win $_nWave2 {("G1" 11)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/lif_unit_tb/dut/i_syn_accum\[17:0\]} \
{/lif_unit_tb/dut/weight_grp_cnt\[6:0\]} \
{/lif_unit_tb/dut/V_mem\[18:0\]} \
{/lif_unit_tb/dut/V_mem_leak\[18:0\]} \
{/lif_unit_tb/dut/V_mem_next\[18:0\]} \
{/lif_unit_tb/dut/post_spike} \
{/lif_unit_tb/dut/ref_active} \
{/lif_unit_tb/dut/weight_mem\[63:0\]} \
{/lif_unit_tb/dut/state_next\[1:0\]} \
{/lif_unit_tb/dut/i_syn_group\[17:0\]} \
{/lif_unit_tb/dut/i_syn_hold\[17:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 11 )} 
wvSetPosition -win $_nWave2 {("G1" 11)}
wvGetSignalClose -win $_nWave2
wvSelectSignal -win $_nWave2 {( "G1" 11 )} 
wvSetRadix -win $_nWave2 -format UDec
wvDisplayGridCount -win $_nWave2 -off
wvGetSignalClose -win $_nWave2
wvReloadFile -win $_nWave2
debExit
