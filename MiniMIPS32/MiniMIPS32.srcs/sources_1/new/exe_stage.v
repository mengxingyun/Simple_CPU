`include "defines.v"

module exe_stage (
    input  wire 					cpu_rst_n,

    // ������׶λ�õ���Ϣ
    input  wire [`ALUTYPE_BUS	] 	exe_alutype_i,
    input  wire [`ALUOP_BUS	    ] 	exe_aluop_i,
    input  wire [`REG_BUS 		] 	exe_src1_i,
    input  wire [`REG_BUS 		] 	exe_src2_i,
    input  wire [`REG_ADDR_BUS 	] 	exe_wa_i,
    input  wire 					exe_wreg_i,
    input  wire                    exe_whilo_i,
    
    // ��hilo�Ĵ�����õ�����       
    input wire [`REG_BUS]          hi_i,
    input wire [`REG_BUS]          lo_i,     

    // ����ִ�н׶ε���Ϣ
    output wire [`ALUOP_BUS	    ] 	exe_aluop_o,
    output wire [`REG_ADDR_BUS 	] 	exe_wa_o,
    output wire 					exe_wreg_o,
    output wire [`REG_BUS 		] 	exe_wd_o,
    output wire                    exe_whilo_o,//�˷�flag
    output wire[`DOUBLE_REG_BUS]   exe_hilo_o//�˷����
    );

    // ֱ�Ӵ�����һ�׶�
    assign exe_aluop_o = (cpu_rst_n == `RST_ENABLE) ? 8'b0 : exe_aluop_i;
    assign exe_whilo_o = (cpu_rst_n == `RST_ENABLE) ? 8'b0 : exe_whilo_i;
    
    wire [`REG_BUS       ]      logicres;       // �����߼�����Ľ��
    wire [`DOUBLE_REG_BUS       ]      mulres; //����˷�������
    wire [`REG_BUS]             hi_t;          //����HI�Ĵ���������ֵ
    wire [`REG_BUS]             lo_t;          //����LO�Ĵ���������ֵ
    wire [`REG_BUS]             moveres;       //�����ƶ������Ľ��
    wire [`REG_BUS]             shiftres;      //������λ����Ľ��
    
    // �����ڲ�������aluop�����߼�����
    assign logicres = (cpu_rst_n == `RST_ENABLE)  ? `ZERO_WORD : 
                      (exe_aluop_i == `MINIMIPS32_AND )  ? (exe_src1_i & exe_src2_i) : `ZERO_WORD;
            
    // �����ڲ�������aluop������������
    
    // �����ڲ�������aluop������λ����
    assign shiftres = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : 
                      (exe_aluop_i ==  `MINIMIPS32_SLL) ? (exe_src2_i << exe_src1_i) : `ZERO_WORD;
    
    // �����ڲ�������aluop���������ƶ����õ����µ�HI��LO�Ĵ�����ֵ
    assign hi_t = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : hi_i;
    assign lo_t = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : lo_i;
    assign moveres = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : 
                     (exe_aluop_i == `MINIMIPS32_MFHI) ? hi_t :
                     (exe_aluop_i == `MINIMIPS32_MFLO) ? lo_t : `ZERO_WORD;
   
   // �����ڲ�������aluop���г˷����㣬ֱ��������һ���׶�
   assign mulres = ($signed(exe_src1_i) * $signed(exe_src2_i));
   assign exe_hilo_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : //ʹ����aluopΪ0x14
                       (exe_aluop_i == `MINIMIPS32_MULT) ? mulres : `ZERO_DWORD;

    assign exe_wa_o   = (cpu_rst_n   == `RST_ENABLE ) ? 5'b0 	 : exe_wa_i;
    assign exe_wreg_o = (cpu_rst_n   == `RST_ENABLE ) ? 1'b0 	 : exe_wreg_i;
    
    // ���ݲ�������alutypeȷ��ִ�н׶����յ����������ȿ����Ǵ�д��Ŀ�ļĴ��������ݣ�Ҳ�����Ƿ������ݴ洢���ĵ�ַ��
    assign exe_wd_o = (cpu_rst_n   == `RST_ENABLE ) ? `ZERO_WORD : 
                      (exe_alutype_i == `LOGIC    ) ? logicres  : 
                      (exe_alutype_i == `MOVE ) ? moveres : 
                      (exe_alutype_i == `SHIFT) ? shiftres : `ZERO_WORD;

endmodule