onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /lif_main_one_to_one_tb/u_dut/clk
add wave -noupdate /lif_main_one_to_one_tb/u_dut/rst_n
add wave -noupdate /lif_main_one_to_one_tb/u_dut/state_reg
add wave -noupdate /lif_main_one_to_one_tb/u_dut/state_next
add wave -noupdate -radix unsigned /lif_main_one_to_one_tb/u_dut/i_syn
add wave -noupdate -radix unsigned /lif_main_one_to_one_tb/u_dut/V_mem
add wave -noupdate -radix unsigned /lif_main_one_to_one_tb/u_dut/V_mem_leak
add wave -noupdate -radix unsigned /lif_main_one_to_one_tb/u_dut/V_mem_next
add wave -noupdate /lif_main_one_to_one_tb/u_dut/V_next_valid
add wave -noupdate /lif_main_one_to_one_tb/u_dut/u_ref/ref_active
add wave -noupdate /lif_main_one_to_one_tb/u_dut/u_ref/cnt
add wave -noupdate -radix unsigned /lif_main_one_to_one_tb/u_dut/V_mem_out
add wave -noupdate /lif_main_one_to_one_tb/u_dut/post_spike
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {90403 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 198
configure wave -valuecolwidth 217
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {87981 ps}
