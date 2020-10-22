`include "defines.v"

module mem_stage (
    input  wire                         cpu_rst_n,

    // 从执行阶段获得的信息
    input  wire [`ALUOP_BUS     ]       mem_aluop_i,
    input  wire [`REG_ADDR_BUS  ]       mem_wa_i,
    input  wire                         mem_wreg_i,
    input  wire [`REG_BUS       ]       mem_wd_i,
    input  wire                         mem_whilo_i,
    input  wire [`DOUBLE_REG_BUS]       mem_hilo_i,
    input  wire                         mem_mreg_i,
    
    // 送至写回阶段的信息
    output wire [`REG_ADDR_BUS  ]       mem_wa_o,
    output wire                         mem_wreg_o,
    output wire [`REG_BUS       ]       mem_dreg_o,
    output wire                         mem_whilo_o,
    output wire [`DOUBLE_REG_BUS]       mem_hilo_o,
    output wire                         mem_mreg_o,
    output wire [`BSEL_BUS]             dre,
    
    //送至数据存储器的信号
    output wire                         dce,
    output wire[`INST_ADDR_BUS]         daddr,
    output wire[`BSEL_BUS]              we
    );

    // 如果当前不是访存指令，则只需要把从执行阶段获得的信息直接输出
    assign mem_wa_o     = (cpu_rst_n == `RST_ENABLE) ? 5'b0  : mem_wa_i;
    assign mem_wreg_o   = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_wreg_i;
    assign mem_dreg_o   = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_wd_i;
    assign mem_whilo_o  = (cpu_rst_n == `RST_ENABLE) ? 1'b0  : mem_whilo_i;
    assign mem_hilo_o   = (cpu_rst_n == `RST_ENABLE) ? 64'b0 : mem_hilo_i;
    assign mem_mreg_o   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : mem_mreg_i;
    
    //确定当前的访存指令
    wire inst_lb = (mem_aluop_i == 8'h90);
    wire inst_lw = (mem_aluop_i == 8'h92);
    
    //获得数据存储器的访问地址
    assign daddr = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : mem_wd_i;
    
    //获得数据存储器读字节使能信号
    assign dre[3] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : 
                    ((inst_lb & (daddr[1:0] == 2'b00)) | inst_lw);
    assign dre[2] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                    ((inst_lb & (daddr[1:0] == 2'b01)) | inst_lw);
    assign dre[1] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                    ((inst_lb & (daddr[1:0] == 2'b10)) | inst_lw);
    assign dre[0] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                    ((inst_lb & (daddr[1:0] == 2'b11)) | inst_lw);
    
    //获得数据存储器使能信号
    assign dce = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                 (inst_lb | inst_lw);
                 
    assign we = 4'b0;
endmodule