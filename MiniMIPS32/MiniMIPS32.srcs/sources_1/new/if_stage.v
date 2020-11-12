`include "defines.v"

module if_stage (
    input 	wire 					cpu_clk_50M,
    input 	wire 					cpu_rst_n,
/*------------------------------��ˮ����ͣbegin-----------------------------*/ 
    input   wire [`STALL_BUS]     stall,
/*------------------------------��ˮ����ͣend-------------------------------*/ 
/*------------------------------ת��ָ�����begin---------------------------*/
    input   wire [`INST_ADDR_BUS]  jump_addr_1,
    input   wire [`INST_ADDR_BUS]  jump_addr_2,
    input   wire [`INST_ADDR_BUS]  jump_addr_3,
    input   wire [`JTSEL_BUS]      jtsel,
    output  wire [`INST_ADDR_BUS]  pc_plus_4,
/*------------------------------ת��ָ�����end-----------------------------*/
    output  wire                     ice,
    output 	reg  [`INST_ADDR_BUS] 	pc,
    output 	wire [`INST_ADDR_BUS]	iaddr
    );
/*--------------------------------ת��ָ���޸�begin----------------------------*/
    assign pc_plus_4 = (cpu_rst_n == `RST_ENABLE) ? `PC_INIT : pc + 4;
    wire [`INST_ADDR_BUS] pc_next; 
    assign pc_next = (jtsel == 2'b00) ? pc_plus_4 : 
                     (jtsel == 2'b01) ? jump_addr_1 : 
                     (jtsel == 2'b10) ? jump_addr_2 : 
                     (jtsel == 2'b11) ? jump_addr_3 : `PC_INIT;                  // ������һ��ָ��ĵ�ַ
/*--------------------------------ת��ָ���޸�end------------------------------*/   

/*---------------------------------��ˮ����ͣbegin-----------------------------*/
    reg ce;
    always @(posedge cpu_clk_50M) begin
		if (cpu_rst_n == `RST_ENABLE) begin
			ce <= `CHIP_DISABLE;		      // ��λ��ʱ��ָ��洢������  
		end else begin
			ce <= `CHIP_ENABLE; 		      // ��λ������ָ��洢��ʹ��
		end
	end
	
    assign ice = (stall[1] == `TRUE_V) ? 0 :ce;

    always @(posedge cpu_clk_50M) begin
        if (ce == `CHIP_DISABLE)
            pc <= `PC_INIT;                   // ָ��洢�����õ�ʱ��PC���ֳ�ʼֵ��MiniMIPS32������Ϊ0x00000000��
        else if (stall[0] == `NOSTOP)begin
            pc <= pc_next;                    // ָ��洢��ʹ�ܺ�PCֵÿʱ�����ڼ�4 	
        end
    end
/*---------------------------------��ˮ����ͣend-------------------------------*/
    
    
    assign iaddr = (ice == `CHIP_DISABLE) ? `PC_INIT : pc;    // ��÷���ָ��洢���ĵ�ַ

endmodule