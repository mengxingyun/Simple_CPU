`include "defines.v"

module wb_stage(
    input  wire                   cpu_rst_n,
    // �ӷô�׶λ�õ���Ϣ
	input  wire [`REG_ADDR_BUS  ] wb_wa_i,
	input  wire                   wb_wreg_i,
	input  wire [`REG_BUS       ] wb_dreg_i,

    // д��Ŀ�ļĴ���������
    output wire [`REG_ADDR_BUS  ] wb_wa_o,
	output wire                   wb_wreg_o,
    output wire [`WORD_BUS      ] wb_wd_o
    );

    assign wb_wa_o      = (cpu_rst_n == `RST_ENABLE) ? 5'b0 : wb_wa_i;
    assign wb_wreg_o    = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : wb_wreg_i;
    assign wb_wd_o = (cpu_rst_n == `RST_ENABLE ) ? `ZERO_WORD : wb_dreg_i;
    
endmodule
