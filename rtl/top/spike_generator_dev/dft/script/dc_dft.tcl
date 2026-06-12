read_file -format ddc {../syn/netlist/top_syn.ddc}
current_design top
link
#set_app_var test_default_black_box true
create_port -dir in SCAN_IN
create_port -dir out SCAN_OUT
create_port -dir in SCAN_EN
set_input_delay  5.0 -clock clk [get_ports {SCAN_IN SCAN_EN test_mode}]
set_output_delay 0.5 -clock clk [get_ports SCAN_OUT]
set_drive        1              [get_ports {SCAN_IN SCAN_EN test_mode}]
set_load         1              [get_ports SCAN_OUT]
set_ideal_network [get_ports {SCAN_EN test_mode}]
set_dft_signal -view exist -type ScanClock -timing {4.5 5.5} -port clk
set_dft_signal -view exist -type Reset -active_state 0 -port rst_n
set_dft_signal -view exist -type TestMode -active_state 1 -port test_mode
create_test_protocol
dft_drc
compile -scan -inc
set_scan_configuration -chain_count 1 -clock_mixing mix_clocks_not_edges -internal_clocks single -add_lockup false
set_dft_signal -view spec -port SCAN_IN -type ScanDataIn
set_dft_signal -view spec -port SCAN_OUT -type ScanDataOut
set_dft_signal -view spec -port SCAN_EN -type ScanEnable -active_state 1
set_scan_path chain1 -scan_data_in SCAN_IN -scan_data_out SCAN_OUT
preview_dft -show all
insert_dft
dft_drc -coverage_estimate > ./report/dft_coverage.log
report_scan_path -view existing_dft -chain all > ./report/dft_chain.log
report_scan_path -view existing_dft -cell all > ./report/dft_cell.log
write -format verilog -hierarchy -output ./netlist/top_scan.vg
write_test_protocol -output ./netlist/top_scan.spf