set_svf ./report/default.svf 

set fp [open "./script/syn_filelist.f" r]
while {[gets $fp line] >= 0} {
    set line [string trim $line]
    if {$line eq "" || [string match "#*" $line] || [string match {//*} $line]} { continue }
    puts "Analyzing $line"
    analyze -format verilog $line
}
close $fp

elaborate top
current_design top
link
uniquify

set mem_cells [get_cells -hier -filter "ref_name =~ *sram* || ref_name =~ *mem*"]
if {[sizeof_collection $mem_cells] > 0} {
    puts "----------------------------------------------------"
    puts "Successfully found [sizeof_collection $mem_cells] memory cells."
    foreach_in_collection cell $mem_cells {
        set_ungroup $cell false
        puts "Protected memory cell: [get_object_name $cell]"
    }
    puts "----------------------------------------------------"
} else {
    puts "Warning: Still cannot find memory cells. Checking instance names..."
    set manual_cells [get_cells -hier -filter "full_name =~ *u_we*"]
    if {[sizeof_collection $manual_cells] > 0} {
        set_ungroup $manual_cells false
        puts "Protected fallback memory cell: [get_object_name $manual_cells]"
    }
}
set_ungroup [get_designs *] true
report_cell [get_cells -hier] > ./report/ungroup_status_check.log

source -echo -verbose ./data/top.sdc
uniquify

set_fix_multiple_port_nets -all -buffer_constants [get_designs *]

set_max_area 0
compile_ultra -area_high_effort_script

change_names -rules verilog -hierarchy
set verilogout_no_tri true
set verilogout_equation false

write -format verilog -hierarchy -output "./netlist/top_syn.v"
write -format ddc     -hierarchy -output "./netlist/top_syn.ddc"
write_sdf -version 1.0 "./netlist/top_syn.sdf"
report_area > ./report/area.log
report_timing > ./report/timing.log
report_port -nosplit > ./report/port_list.log
report_hierarchy > ./report/hierarchy.log
report_reference > ./report/reference.log
report_cell > ./report/cell_report.log

puts "----------------------------------------------------"
puts "Synthesis Finished!"
puts "Final Port Count (Expected ~22): [sizeof_collection [get_ports *]]"
puts "----------------------------------------------------"
exit