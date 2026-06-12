set_messages -log tmax.log -replace
read_netlist ../netlist/top_scan.vg
read_netlist /home/cell_lib/CBDK_TSMC90GUTM_Arm_f1.0/CIC/Verilog/tsmc090.v
set_build -black_box spike_gen_mem
run_build_model top
set_rules C4 ignore
run_drc ../netlist/top_scan.spf
add_faults -all
set_pat -internal
run_atpg -auto
set_faults -fault_coverage
set_faults -summary verbose
report_summaries > ./report/atpg_coverage.rpt
exit