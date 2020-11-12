`include "defines.v"

module ifid_reg (
	input  wire 						cpu_clk_50M,
	input  wire 						cpu_rst_n,
/*-------------------------流水线暂停begin------------------------------------*/
    input  wire [`STALL_BUS]           stall,
/*-------------------------流水线暂停end--------------------------------------*/


	// 来自取指阶段的信息  
	input  wire [`INST_ADDR_BUS]       if_pc,
	input  wire [`INST_ADDR_BUS]       if_pc_plus_4,//转移指令添加
	
	// 送至译码阶段的信息  
	output reg  [`INST_ADDR_BUS]       id_pc,
	output reg  [`INST_ADDR_BUS]       id_pc_plus_4//转移指令添加
	);

	always @(posedge cpu_clk_50M) begin
	    // 复位的时候将送至译码阶段的信息清0
		if (cpu_rst_n == `RST_ENABLE) begin
			id_pc 	<= `PC_INIT;
			id_pc_plus_4 <= `ZERO_WORD;//转移指令添加
		end
/*-----------------------------------------------流水线暂停begin------------------------------------*/
		// 将来自取指阶段的信息寄存并送至译码阶段
		else if(stall[1] == `STOP && stall[2] == `NOSTOP)begin
			id_pc	<=  `ZERO_WORD;	
			id_pc_plus_4 <= `ZERO_WORD;//转移指令添加	
		end
		else if(stall[1] == `NOSTOP) begin
		    id_pc <= if_pc;
		    id_pc_plus_4 <= if_pc_plus_4;
		end
	end
/*-----------------------------------------------流水线暂停end---------------------------------------*/

endmodule