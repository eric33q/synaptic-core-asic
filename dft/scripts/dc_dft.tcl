# 讀取合成後的設計
read_file -format ddc {../syn/netlist/top_syn.ddc}
current_design top
link
# ==========================================
# 建立掃描鍊專用的 I/O Port
# ==========================================
create_port -dir in SCAN_IN
create_port -dir out SCAN_OUT
create_port -dir in SCAN_EN

# 為 SCAN 與測試腳位套用物理條件 (test_mode 已經存在，所以可以直接 get_ports 抓取)
set_input_delay  5.0 -clock clk [get_ports {SCAN_IN SCAN_EN test_mode}]
set_output_delay 0.5 -clock clk [get_ports SCAN_OUT]
set_drive        1              [get_ports {SCAN_IN SCAN_EN test_mode}]
set_load         1              [get_ports SCAN_OUT]

# 宣告 SCAN_EN 與 test_mode 為理想網路
set_ideal_network [get_ports {SCAN_EN test_mode}]

# ==========================================
# 設定現有的 Clock、Reset 與 DFT 訊號
# ==========================================
set_dft_signal -view exist -type ScanClock -timing {4.5 5.5} -port clk
set_dft_signal -view exist -type Reset -active_state 0 -port rst_n

# 宣告 Test Mode 訊號，讓 ATPG 工具知道測試時必須將此腳位保持為 1
set_dft_signal -view exist -type TestMode -active_state 1 -port test_mode

# 建立與檢查 Test Protocol
create_test_protocol
dft_drc

# 替換為 Scan-FF (Scan Synthesis)
compile -scan -map_effort high -area_effort high -boundary_optimization 

# 配置與插入掃描鍊 (Scan Chain Insertion)
set_scan_configuration -chain_count 1 -clock_mixing mix_clocks_not_edges -internal_clocks single -add_lockup false

set_dft_signal -view spec -port SCAN_IN -type ScanDataIn
set_dft_signal -view spec -port SCAN_OUT -type ScanDataOut
set_dft_signal -view spec -port SCAN_EN -type ScanEnable -active_state 1

set_scan_path chain1 -scan_data_in SCAN_IN -scan_data_out SCAN_OUT

preview_dft -show all
insert_dft

# 產生報告 
dft_drc -coverage_estimate > ./reports/dft_coverage.log
report_scan_path -view existing_dft -chain all > ./reports/dft_chain.log
report_scan_path -view existing_dft -cell all > ./reports/dft_cell.log

# 輸出結果
write -format verilog -hierarchy -output ./netlist/top_scan.vg
write_test_protocol -output ./netlist/top_scan.spf