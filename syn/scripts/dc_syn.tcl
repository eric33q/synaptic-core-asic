<<<<<<< update
 # 1. 讀取 filelist.f (使用 analyze 指令)
 set_svf ./reports/default.svf 
# analyze 會分析語法，並將中間檔存入 work 目錄
 analyze -format verilog -f filelist.f
#
 # 2. 建立設計 (Elaborate)
 # 將分析過的模組組合成一個完整的電路架構
 elaborate TOP
#
 # 3. 定義頂層與連結
 current_design TOP
 link
 check_design
#
 # 4. 設定約束 (請確認 TOP.sdc 內的時鐘名稱與 TOP.v 一致)
 source -echo -verbose TOP.sdc
#
 # 5. 設計環境優化
 # uniquify 針對多次呼叫的相同子模組進行獨立優化
 uniquify
 set_fix_multiple_port_nets -all -buffer_constants [get_designs *]
#
 # 6. 執行綜合 (Synthesis)
 # 加入 -boundary_optimization 以優化 TOP 下各個子電路間的邏輯
 compile -map_effort high -boundary_optimization
#
 # 7. 匯出 Netlist 到專門的資料夾
 write -format verilog -hierarchy -output "./netlist/top_syn.v"
 write_sdf -version 1.0 "./netlist/top_syn.sdf"
#
<<<<<<< refs/remotes/origin/update
 # 8. 產出報表到專門的資料夾
 report_area > ./reports/area.log
 report_timing > ./reports/timing.log
=======
 # 9. 產出報表到專門的資料夾
 report_area > ./reports/typical/area.log
 report_timing > ./reports/typical/timing.log
 report_power > ./reports/typical/power.log
 report_qor > ./reports/typical/qor.log
 check_design > ./reports/typical/check_design.log
 report_constraint -all_violators > ./reports/typical/violation.log
>>>>>>> local
=======
# =======================================================
# 1. 讀取設計檔 (analyze)
# =======================================================
set_svf ./reports/default.svf 
set fp [open "../syn_filelist.f" r]
while {[gets $fp line] >= 0} {
    set line [string trim $line]
    if {$line eq "" || [string match "#*" $line] || [string match {//*} $line]} { continue }
    puts "Analyzing $line"
    analyze -format verilog $line
}
close $fp

# =======================================================
# 2. 建立設計 (Elaborate)
# =======================================================
elaborate top
current_design top
link

# =======================================================
# 3. 定義層級優化策略 (解決 UID-109 找不到設計的問題)
# =======================================================

# 1. 執行 uniquify 確保每個實例都有唯一的屬性設定空間
uniquify

# 2. 改用 get_cells 並搭配 -hierarchical 搜尋整個電路
# 我們針對 "參考名稱 (ref_name)" 進行過濾，這能精準抓到 SRAM
set mem_cells [get_cells -hier -filter "ref_name =~ *sram* || ref_name =~ *mem*"]

if {[sizeof_collection $mem_cells] > 0} {
    puts "----------------------------------------------------"
    puts "Successfully found [sizeof_collection $mem_cells] memory cells."
    
    # 逐一針對實例設定不打散
    foreach_in_collection cell $mem_cells {
        set_ungroup $cell false
        # 如果你想更保險，可以連 dont_touch 一起下 (選用)
        # set_dont_touch $cell
    }
    puts "----------------------------------------------------"
} else {
    puts "Warning: Still cannot find memory cells. Checking instance names..."
    # 備案：如果連 ref_name 都抓不到，試著抓你 RTL 裡的實例名稱 (如 u_we)
    set manual_cells [get_cells -hier -filter "full_name =~ *u_we*"]
    if {[sizeof_collection $manual_cells] > 0} {
        set_ungroup $manual_cells false
    }
}

# 3. 將其餘所有邏輯設計設定為「允許打散」，以壓縮面積
# 剛才被設為 false 的 cell 會保留其層級
set_ungroup [get_designs *] true

# [進階診斷] 在編譯前直接印出目前的 ungroup 狀態，確認保護是否生效
report_cell [get_cells -hier] > ./reports/ungroup_status_check.log

# =======================================================
# 4. 設定約束
# =======================================================
source -echo -verbose ./data/top.sdc

# =======================================================
# 5. 設計環境優化
# =======================================================
uniquify
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]

# =======================================================
# 6. 執行綜合 (Synthesis)
# =======================================================
set_max_area 0

# 建議使用 compile_ultra，若環境不支援則改回 compile
# -ungroup_all 選項會配合前面的 set_dont_ungroup 進行優化
compile_ultra -area_high_effort_script

# =======================================================
# 7. 匯出前置處理
# =======================================================
change_names -rules verilog -hierarchy
set verilogout_no_tri true
set verilogout_equation false

# =======================================================
# 8. 匯出 Netlist
# =======================================================
write -format verilog -hierarchy -output "./netlist/top_syn.v"
write -format ddc     -hierarchy -output "./netlist/top_syn.ddc"
write_sdf -version 1.0 "./netlist/top_syn.sdf"

# =======================================================
# 9. 產出詳細報表
# =======================================================
report_area > ./reports/area.log
report_timing > ./reports/timing.log
report_port -nosplit > ./reports/port_list.log

# 修正：移除先前報錯的 -nolevel 選項
report_hierarchy > ./reports/hierarchy.log
report_reference > ./reports/reference.log
report_cell > ./reports/cell_report.log

puts "----------------------------------------------------"
puts "Synthesis Finished!"
puts "Final Port Count (Expected ~22): [sizeof_collection [get_ports *]]"
puts "----------------------------------------------------"

exit
>>>>>>> local