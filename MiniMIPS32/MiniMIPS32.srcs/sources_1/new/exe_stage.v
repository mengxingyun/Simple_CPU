`include "defines.v"

module exe_stage (
    input  wire 					cpu_rst_n,

    // 从译码阶段获得的信息
    input  wire [`ALUTYPE_BUS	] 	exe_alutype_i,
    input  wire [`ALUOP_BUS	    ] 	exe_aluop_i,
    input  wire [`REG_BUS 		] 	exe_src1_i,
    input  wire [`REG_BUS 		] 	exe_src2_i,
    input  wire [`REG_ADDR_BUS 	] 	exe_wa_i,
    input  wire 					exe_wreg_i,
    input  wire                    exe_whilo_i,

    // 送至执行阶段的信息
    output wire [`ALUOP_BUS	    ] 	exe_aluop_o,
    output wire [`REG_ADDR_BUS 	] 	exe_wa_o,
    output wire 					exe_wreg_o,
    output wire [`REG_BUS 		] 	exe_wd_o,
    output wire                    exe_whilo_o,//乘法flag
    output wire[`DOUBLE_REG_BUS]   exe_hilo_o//乘法结果
    );

    // 直接传到下一阶段
    assign exe_aluop_o = (cpu_rst_n == `RST_ENABLE) ? 8'b0 : exe_aluop_i;
    assign exe_whilo_o = (cpu_rst_n == `RST_ENABLE) ? 8'b0 : exe_whilo_i;
    
    wire [`REG_BUS       ]      logicres;       // 保存逻辑运算的结果
    wire [`DOUBLE_REG_BUS       ]      mulres; //保存乘法运算结果
    
    // 根据内部操作码aluop进行逻辑运算
    assign logicres = (cpu_rst_n == `RST_ENABLE)  ? `ZERO_WORD : 
                      (exe_aluop_i == `MINIMIPS32_AND )  ? (exe_src1_i & exe_src2_i) : `ZERO_WORD;
            
    // 根据内部操作码aluop进行算术运算
   
   // 根据内部操作码aluop进行乘法运算，直接送入下一个阶段
   assign mulres = ($signed(exe_src1_i) * $signed(exe_src2_i));
   assign exe_hilo_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : //使能且aluop为0x14
                       (exe_aluop_i == `MINIMIPS32_MULT) ? mulres : `ZERO_DWORD;

    assign exe_wa_o   = (cpu_rst_n   == `RST_ENABLE ) ? 5'b0 	 : exe_wa_i;
    assign exe_wreg_o = (cpu_rst_n   == `RST_ENABLE ) ? 1'b0 	 : exe_wreg_i;
    
    // 根据操作类型alutype确定执行阶段最终的运算结果（既可能是待写入目的寄存器的数据，也可能是访问数据存储器的地址）
    assign exe_wd_o = (cpu_rst_n   == `RST_ENABLE ) ? `ZERO_WORD : 
                      (exe_alutype_i == `LOGIC    ) ? logicres  : `ZERO_WORD;

endmodule