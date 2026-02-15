# 1. 定義時脈 (針對 180nm，10ns 是非常穩健的目標)
create_clock -name clk -period 10.0 [get_ports clk] 

# 2. 時脈網路設定
set_dont_touch_network      [get_clocks clk]
set_fix_hold                [get_clocks clk]
set_clock_uncertainty  0.1  [get_clocks clk]
set_clock_latency      0.5  [get_clocks clk]
set_ideal_network           [get_ports clk]

# 3. I/O 延遲
set_input_delay  5.0   -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 0.5   -clock clk [all_outputs] 

# 4. 負載與驅動
set_load         1   [all_outputs]
set_drive        1   [all_inputs]

# 5. 操作環境設定 (關鍵修改：指向 T180 庫)
# 通常 TSRI 的 slow library 名稱為 slow (或是 tsmc18_slow)
set_operating_conditions -max_library slow -max slow

# 6. 線路負載模型 (關鍵修改：T180 的模型通常稱為 "tsmc18_wl10")
# 請檢查你的 library 報表確認正確名稱
set_wire_load_model -name tsmc18_wl10 -library slow 

# 7. 設計規則
set_max_fanout 20 [all_inputs]
set_max_fanout 20 [get_designs TOP]
