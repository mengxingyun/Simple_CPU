`include "defines.v"

module exemem_reg (
    input  wire 				cpu_clk_50M,
    input  wire 				cpu_rst_n,

    // ����ִ�н׶ε���Ϣ
    input  wire [`ALUOP_BUS   ] exe_aluop,
    input  wire [`REG_ADDR_BUS] exe_wa,
    input  wire                 exe_wreg,
    input  wire [`REG_BUS 	  ] exe_wd,
    input  wire                 exe_whilo,
    input  wire [`DOUBLE_REG_BUS] exe_hilo, 
    input  wire                   exe_mreg,
    
    // �͵��ô�׶ε���Ϣ 
    output reg  [`ALUOP_BUS   ] mem_aluop,
    output reg  [`REG_ADDR_BUS] mem_wa,
    output reg                  mem_wreg,
    output reg  [`REG_BUS 	  ] mem_wd,
    output reg                  mem_whilo,
    output reg [`DOUBLE_REG_BUS] mem_hilo,
    output reg                   mem_mreg
    );

    always @(posedge cpu_clk_50M) begin
    if (cpu_rst_n == `RST_ENABLE) begin
        mem_aluop              <= `MINIMIPS32_SLL;
        mem_wa 				   <= `REG_NOP;
        mem_wreg   			   <= `WRITE_DISABLE;
        mem_wd   			   <= `ZERO_WORD;
        mem_whilo              <= `WRITE_DISABLE;
        mem_hilo               <= `ZERO_DWORD;
        mem_mreg               <= `WRITE_DISABLE;
    end
    else begin
        mem_aluop              <= exe_aluop;
        mem_wa 				   <= exe_wa;
        mem_wreg 			   <= exe_wreg;
        mem_wd 		    	   <= exe_wd;
        mem_whilo              <= exe_whilo;
        mem_hilo               <= exe_hilo;
        mem_mreg               <= exe_mreg;
    end
  end

endmodule