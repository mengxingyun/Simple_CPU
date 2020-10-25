`include "defines.v"

module id_stage(
    input  wire                     cpu_rst_n,
    
    // ��ȡָ�׶λ�õ�PCֵ
    input  wire [`INST_ADDR_BUS]    id_pc_i,

    // ��ָ��洢��������ָ����
    input  wire [`INST_BUS     ]    id_inst_i,

    // ��ͨ�üĴ����Ѷ��������� 
    input  wire [`REG_BUS      ]    rd1,
    input  wire [`REG_BUS      ]    rd2,
      
    // ����ִ�н׶ε�������Ϣ
    output wire [`ALUTYPE_BUS  ]    id_alutype_o,
    output wire [`ALUOP_BUS    ]    id_aluop_o,
    output wire                     id_whilo_o,//�˷���ʶλ
    output wire                     id_mreg_o,// �洢�����Ĵ�����ʹ���ź�
    output wire [`REG_ADDR_BUS ]    id_wa_o,//д��Ŀ�ļĴ����ĵ�ַ
    output wire                     id_wreg_o,
    output wire [`REG_BUS]          id_din_o,// д���ڴ������

    // ����ִ�н׶ε�Դ������1��Դ������2
    output wire [`REG_BUS      ]    id_src1_o,
    output wire [`REG_BUS      ]    id_src2_o,
      
    // ������ͨ�üĴ����Ѷ˿ڵ�ʹ�ܺ͵�ַ
    output wire                     rreg1,
    output wire [`REG_ADDR_BUS ]    ra1,
    output wire                     rreg2,
    output wire [`REG_ADDR_BUS ]    ra2
    );
    
    // ����С��ģʽ��ָ֯����
    wire [`INST_BUS] id_inst = {id_inst_i[7:0], id_inst_i[15:8], id_inst_i[23:16], id_inst_i[31:24]};

    // ��ȡָ�����и����ֶε���Ϣ
    wire [5 :0] op   = id_inst[31:26];
    wire [5 :0] func = id_inst[5 : 0];
    wire [4 :0] rd   = id_inst[15:11];
    wire [4 :0] rs   = id_inst[25:21];
    wire [4 :0] rt   = id_inst[20:16];
    wire [4 :0] sa   = id_inst[10: 6];
    wire [15:0] imm  = id_inst[15: 0]; 

    /*-------------------- ��һ�������߼���ȷ����ǰ��Ҫ�����ָ�� --------------------*/
    wire inst_reg  = ~|op;
    wire inst_and  = inst_reg& func[5]&~func[4]&~func[3]& func[2]&~func[1]&~func[0];
    wire inst_mult = inst_reg & ~func[5] & func[4] & func[3] & ~func[2] & ~func[1] & ~func[0];// 1: mult
    wire inst_mfhi = inst_reg & ~ func[5] & func[4] & ~func[3] & ~func[2] & ~func[1] & ~func[0];//2: move from hi
    wire inst_mflo = inst_reg & ~func[5] & func[4] & ~func[3] & ~func[2] & func[1] & ~func[0];//3: move from lo
    wire inst_sll  = inst_reg & ~func[5] & ~func[4] & ~func[3] & ~func[2] & ~func[1] & ~func[0];//4: sll
    wire inst_ori  = ~op[5] & ~op[4] & op[3] & op[2] & ~op[1] & op[0]; //5: ori
    wire inst_lui  = ~op[5] & ~op[4] & op[3] & op[2] & op[1] & op[0];  //6: lui
    wire inst_lb   = op[5] & ~op[4] & ~op[3] & ~op[2] & ~op[1] & ~op[0]; //7: lb
    wire inst_lw   = op[5] & ~op[4] & ~op[3] & ~op[2] & op[1] & op[0]; //8: lw
    wire inst_sb   = op[5] & ~op[4] & op[3] & ~op[2] & ~op[1] & ~op[0]; //9: sb
    wire inst_sh   = op[5] & ~op[4] & op[3] & ~op[2] & ~op[1] & op[0]; //10: sh
    wire inst_sw   = op[5] & ~op[4] & op[3] & ~op[2] & op[1] & op[0]; //11: sw
    wire inst_add = inst_reg & func[5] & ~func[4] & ~func[3] & ~func[2] & ~func[1] & ~func[0]; //12: add
    wire inst_subu = inst_reg & func[5] & ~func[4] & ~func[3] & ~func[2] & func[1] & func[0]; //13: subu
    wire inst_slt = inst_reg & func[5] & ~func[4] & func[3] & ~func[2] & func[1] & ~func[0]; //14: slt
    wire inst_addiu = ~op[5] & ~op[4] & op[3] & ~op[2] & ~op[1] & op[0]; //15: addiu
    wire inst_sltiu = ~op[5] & ~op[4] & op[3] & ~op[2] & op[1] & op[0]; //16: sltiu(imm�з�����չ��32λ�����޷��űȽ�)
    wire inst_addi = ~op[5] & ~op[4] & op[3] & ~op[2] & ~op[1] & ~op[0]; //17: addi(�����������ɴ�������쳣)
    wire inst_slti = ~op[5] & ~op[4] & op[3] & ~op[2] & op[1] & ~op[0]; //18: slti(imm�з�����չ�з��űȽ�)
    wire inst_andi = ~op[5] & ~op[4] & op[3] & op[2] & ~op[1] & ~op[0]; //19: andi(imm�޷�����չ)
    wire inst_xori = ~op[5] & ~op[4] & op[3] & op[2] & op[1] & ~op[0]; //20 : xori(imm�޷�����չ)
    /*------------------------------------------------------------------------------*/

    /*-------------------- �ڶ��������߼������ɾ�������ź� --------------------*/
    // ��������alutype
    assign id_alutype_o[2] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : inst_sll;
    assign id_alutype_o[1] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_and | inst_mfhi | inst_mflo | inst_ori | inst_lui | 
                                                                  inst_andi | inst_xori);
    assign id_alutype_o[0] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_mfhi | inst_mflo | inst_lb | inst_lw | inst_sb | inst_sh | 
                                                                  inst_sw | inst_add | inst_subu | inst_slt | inst_addiu | 
                                                                  inst_sltiu | inst_addi | inst_slti);

    // �ڲ�������aluop
    assign id_aluop_o[7]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_lb | inst_lw | inst_sb | inst_sh | inst_sw);
    assign id_aluop_o[6]   = 1'b0;
    assign id_aluop_o[5]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_slt | inst_sltiu | inst_slti);
    assign id_aluop_o[4]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_and | inst_mult | inst_sll | inst_ori | inst_lw | inst_lb |
                                                                  inst_sb | inst_sw | inst_sh | inst_add | inst_subu | inst_addiu | 
                                                                  inst_addi | inst_addi | inst_xori);
    assign id_aluop_o[3]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_and | inst_mflo | inst_mfhi | inst_ori | inst_sb | inst_sh |
                                                                  inst_sw | inst_add | inst_subu | inst_addiu | inst_addi | 
                                                                  inst_andi | inst_xori);
    assign id_aluop_o[2]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_and | inst_mult | inst_mfhi | inst_mflo | inst_ori | inst_lui | 
                                                                  inst_slt | inst_sltiu | inst_slti | inst_andi | inst_xori);
    assign id_aluop_o[1]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_lw | inst_sw | inst_subu | inst_slt | inst_sltiu | 
                                                                  inst_slti | inst_xori);
    assign id_aluop_o[0]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_mflo | inst_sll | inst_ori | inst_lui | inst_sh | inst_subu |
                                                                  inst_addiu | inst_sltiu);

    // дͨ�üĴ���ʹ���ź�
    assign id_wreg_o       = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_and | inst_mfhi | inst_mflo | inst_sll 
                                                                  | inst_ori | inst_lui | inst_lb | inst_lw |
                                                                  inst_add | inst_subu | inst_slt | inst_addiu | inst_sltiu | 
                                                                  inst_addi | inst_slti | inst_andi | inst_xori);
    
    //дHILO�Ĵ���ʹ���ź�
    assign id_whilo_o = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : inst_mult;
    
    //��λʹ���ź�
    wire shift = inst_sll;
    
    //������ʹ���ź�
    wire immsel = inst_ori | inst_lui | inst_lw | inst_lb | inst_sb | inst_sh | inst_sw | inst_addiu | inst_sltiu | 
                   inst_addi | inst_slti | inst_andi | inst_xori;
    
    //Ŀ�ļĴ���ѡ���ź�(rt����rd)
    wire rtsel = inst_ori | inst_lui | inst_lb | inst_lw | inst_addiu | inst_sltiu | inst_addi | inst_slti | inst_andi | inst_xori;
    
    //������չʹ���ź�
    wire sext = inst_lb | inst_lw | inst_sb | inst_sh | inst_sw | inst_addiu | inst_sltiu | inst_addi | inst_slti;
    
    //���ظ߰���ʹ���ź�
    wire upper = inst_lui;
    
    //�洢�����Ĵ���ʹ���ź�
    assign id_mreg_o = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_lb | inst_lw);
    
    // ��ͨ�üĴ����Ѷ˿�1ʹ���ź�
    assign rreg1 = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_and | inst_mult | inst_ori | inst_lb | inst_lw | inst_sb | inst_sh | 
                                                        inst_sw | inst_add | inst_subu | inst_sltiu | inst_slt | inst_addiu | 
                                                        inst_addi | inst_slti | inst_xori | inst_andi);
    // ��ͨ�üĴ����Ѷ��˿�2ʹ���ź�
    assign rreg2 = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_and | inst_mult | inst_sll | inst_sb | inst_sh | inst_sw | 
                                                        inst_add | inst_subu | inst_slt);
    
    /*------------------------------------------------------------------------------*/

    // ��ͨ�üĴ����Ѷ˿�1�ĵ�ַΪrs�ֶΣ����˿�2�ĵ�ַΪrt�ֶ�
    assign ra1   = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : rs;
    assign ra2   = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : rt;
    
    //���ָ���������Ҫ��������
    wire [31:0] imm_ext = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : 
                           (upper == `UPPER_ENABLE) ? (imm << 16) :
                           (sext == `SIGNED_EXT) ? {{16{imm[15]}}, imm} : {{16{1'b0}}, imm};       
                                            
    // ��ô�д��Ŀ�ļĴ����ĵ�ַ��rt��rd��
    assign id_wa_o      = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : (rtsel == `RT_ENABLE) ? rt : rd;
    
    //��÷ô�׶�Ҫ�������ݴ洢��������(rt������rd2)
    assign id_din_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : rd2;             

    // ���Դ������1�����shift�ź���Ч����Դ������1Ϊ��λλ��������Ϊ�Ӷ�ͨ�üĴ����Ѷ˿�1��õ�����
    assign id_src1_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                       (shift == `SHIFT_ENABLE)   ? {27'b0, sa} :
                       (rreg1 == `READ_ENABLE   ) ? rd1 : `ZERO_WORD;

    // ���Դ������2�����immsel�ź���Ч����Դ������1Ϊ������������Ϊ�Ӷ�ͨ�üĴ����Ѷ˿�2��õ�����
    assign id_src2_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                       (immsel == `IMM_ENABLE) ? imm_ext :
                       (rreg2 == `READ_ENABLE   ) ? rd2 : `ZERO_WORD;
endmodule
