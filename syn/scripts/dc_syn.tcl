 # 1. 讀取 filelist.f (使用 analyze 指令)
 set_svf ./reports/default.svf 
# 逐行讀取 filelist.f
set fp [open "../syn_filelist.f" r]
while {[gets $fp line] >= 0} {
    set line [string trim $line]

    if {$line eq ""} { continue }
    if {[string match "#*" $line]} { continue }
    if {[string match {//*} $line]} { continue }

    puts "Analyzing $line"
    analyze -format verilog $line
}
close $fp
 # 2. 建立設計 (Elaborate)
 # 將分析過的模組組合成一個完整的電路架構
 elaborate top
#
 # 3. 定義頂層與連結
 current_design top
 link
 check_design
#
 # 4. 設定約束 (請確認 TOP.sdc 內的時鐘名稱與 TOP.v 一致)
 source -echo -verbose ./data/top.sdc
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
 # 8. 產出報表到專門的資料夾
 report_area > ./reports/area.log
 report_timing > ./reports/timing.log
