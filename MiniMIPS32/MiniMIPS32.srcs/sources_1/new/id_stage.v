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
    
    /*------------------------------�����������begin--------------------------------*/
    //��ִ�н׶λ�õ�д���ź�
    input  wire                     exe2id_wreg,//д�Ĵ���ʹ���ź�
    input  wire [`REG_ADDR_BUS]     exe2id_wa,//д�Ĵ�����ַ
    input  wire [`INST_BUS]         exe2id_wd,//д�Ĵ�������
    
    //�ӷô�׶λ�õ�д���ź�
    input  wire                     mem2id_wreg,
    input  wire [`REG_ADDR_BUS]     mem2id_wa,
    input  wire [`INST_BUS]         mem2id_wd,
    /*------------------------------�����������end--------------------------------*/
    /*------------------------------ת��ָ�����begin------------------------------*/
    input  wire [`INST_ADDR_BUS]    pc_plus_4,
    
    output wire [`INST_ADDR_BUS]    jump_addr_1,
    output wire [`INST_ADDR_BUS]    jump_addr_2,
    output wire [`INST_ADDR_BUS]    jump_addr_3,
    output wire [`JTSEL_BUS]        jtsel,
    output wire [`INST_ADDR_BUS]    ret_addr,
    /*------------------------------ת��ָ�����end--------------------------------*/
    
      
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
    wire inst_addu = inst_reg & func[5] & ~func[4] & ~func[3] & ~func[2] & ~func[1] & func[0]; //21: addu(�ӷ�������������쳣)
    wire inst_sub = inst_reg & func[5] & ~func[4] & ~func[3] & ~func[2] & func[1] & ~func[0]; //22: sub(������ ��������쳣)
    wire inst_sltu = inst_reg & func[5] & ~func[4] & func[3] & ~func[2] & func[1] & func[0];//23: sltu(rs��rt�����޷��űȽ�)
    wire inst_multu = inst_reg & ~func[5] & func[4] & func[3] & ~func[2] & ~func[1] & func[0]; //24: multu(�޷��ų˷�)
    wire inst_xor = inst_reg & func[5] & ~func[4] & ~func[3] & func[2] & func[1] & ~func[0]; //25: xor(��λ���)
    wire inst_or = inst_reg & func[5] & ~func[4] & ~func[3] & func[2] & ~func[1] & func[0]; //26: or(��λ��)
    wire inst_nor = inst_reg & func[5] & ~func[4] & ~func[3] & func[2] & func[1] & func[0]; //27: nor(��λ���)
    wire inst_sllv = inst_reg & ~func[5] & ~func[4] & ~func[3] & func[2] & ~func[1] & ~func[0];//28: sllv(�߼����ƣ���λλ��Ϊrs�ĵ�5λ)
    wire inst_sra = inst_reg & ~func[5] & ~func[4] & ~func[3] & ~func[2] & func[1] & func[0];//29: sra(��������)
    wire inst_srav = inst_reg & ~func[5] & ~func[4] & ~func[3] & func[2] & func[1] & func[0];//30: srav(�������ƣ���λλ������rs�ĵ���λ)
    wire inst_srl = inst_reg & ~func[5] & ~func[4] & ~func[3] & ~func[2] & func[1] & ~func[0];//31: srl(�߼�����)
    wire inst_srlv = inst_reg & ~func[5] & ~func[4] & ~func[3] & func[2] & func[1] & ~func[0]; //32: srlv(�߼����ƣ���λλ������rs�ĵ���λ)
    wire inst_mthi = inst_reg & ~func[5] & func[4] & ~func[3] & ~func[2] & ~func[1] & func[0]; //33: mthi(rs����HI�Ĵ���)
    wire inst_mtlo = inst_reg & ~func[5] & func[4] & ~func[3] & ~func[2] & func[1] & func[0]; //34: mtlo(rs����LO�Ĵ���)
    wire inst_lbu = op[5] & ~op[4] & ~op[3] & op[2] & ~op[1] & ~op[0]; //35: lbu(rs + �������з�����չ��Ϊ�ô��ַ���޷�����չbyte)
    wire inst_lh = op[5] & ~op[4] & ~op[3] & ~op[2] & ~op[1] & op[0]; //36: lh(�������ֽڷ�����չ)
    wire inst_lhu = op[5] & ~op[4] & ~op[3] & op[2] & ~op[1] & op[0]; //37: lhu(���������ֽ��޷�����չ)
    /*----------------------------ת��ָ�����begin-------------------------------*/
    wire inst_j = ~op[5] & ~op[4] & ~op[3] & ~op[2] & op[1] & ~op[0]; //38: j(PC��������תPC+4����λ��instr_index������λƴ�Ӷ��ɵ�ָ�)
    wire inst_jal = ~op[5] & ~op[4] & ~op[3] & ~op[2] & op[1] & op[0]; //39: jal(ͬj,����Ҫ��PC+8�浽$ra��)
    wire inst_jr = inst_reg & ~func[5] & ~func[4] & func[3] & ~func[2] & ~func[1] & ~func[0]; //40: jr(������ת�ƣ�ת��Ŀ���ַΪ�Ĵ���rs��ֵ)
    wire inst_beq = ~op[5] & ~op[4] & ~op[3] & op[2] & ~op[1] & ~op[0]; //41: beq(���rs=rt�е�ֵ������ת��PC + 4 + imm << 2)
    wire inst_bne = ~op[5] & ~op[4] & ~op[3] & op[2] & ~op[1] & op[0]; //42: bne(���rs!=rt�е�ֵ������ת��PC + 4 + imm << 2)
    /*----------------------------ת��ָ�����end---------------------------------*/

    /*-------------------- �ڶ��������߼������ɾ�������ź� --------------------*/
    // ��������alutype
    assign id_alutype_o[2] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_sll | inst_sllv | inst_srl | inst_srlv | inst_sra | 
                                                                  inst_srav | inst_j | inst_jal | inst_jr | inst_beq | inst_bne);
    assign id_alutype_o[1] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_and | inst_mfhi | inst_mflo | inst_ori | inst_lui | 
                                                                  inst_andi | inst_xori | inst_or | inst_xor | inst_nor | 
                                                                  inst_mtlo | inst_mthi);
    assign id_alutype_o[0] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_mfhi | inst_mflo | inst_lb | inst_lw | inst_sb | inst_sh | 
                                                                  inst_sw | inst_add | inst_subu | inst_slt | inst_addiu | 
                                                                  inst_sltiu | inst_addi | inst_slti | inst_addu | inst_sub | 
                                                                  inst_sltu | inst_mtlo | inst_mthi | inst_lbu | inst_lh | 
                                                                  inst_lhu | inst_j | inst_jal | inst_jr | inst_beq | inst_bne );

    // �ڲ�������aluop
    assign id_aluop_o[7]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_lb | inst_lw | inst_sb | inst_sh | inst_sw | inst_lh | 
                                                                  inst_lbu | inst_lhu);
    assign id_aluop_o[6]   = 1'b0;
    assign id_aluop_o[5]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_slt | inst_sltiu | inst_slti | inst_sltu | inst_j | inst_jal | 
                                                                  inst_jr | inst_beq | inst_bne);
    assign id_aluop_o[4]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_and | inst_mult | inst_sll | inst_ori | inst_lw | inst_lb |
                                                                  inst_sb | inst_sw | inst_sh | inst_add | inst_subu | inst_addiu | 
                                                                  inst_addi | inst_addi | inst_xori | inst_addu | inst_sub | 
                                                                  inst_multu | inst_or | inst_xor | inst_nor | inst_sllv | 
                                                                  inst_srl | inst_srlv | inst_sra | inst_srav | inst_lh | 
                                                                  inst_lbu | inst_lhu | inst_beq | inst_bne);
    assign id_aluop_o[3]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_and | inst_mflo | inst_mfhi | inst_ori | inst_sb | inst_sh |
                                                                  inst_sw | inst_add | inst_subu | inst_addiu | inst_addi | 
                                                                  inst_andi | inst_xori | inst_addu | inst_sub | inst_or | 
                                                                  inst_xor | inst_nor | inst_mthi | inst_mtlo | inst_j | 
                                                                  inst_jal | inst_jr);
    assign id_aluop_o[2]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_and | inst_mult | inst_mfhi | inst_mflo | inst_ori | inst_lui | 
                                                                  inst_slt | inst_sltiu | inst_slti | inst_andi | inst_xori | 
                                                                  inst_sltu | inst_multu | inst_or | inst_xor | inst_nor | inst_mthi | 
                                                                  inst_mtlo | inst_lhu | inst_j | inst_jal | inst_jr );
    assign id_aluop_o[1]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_lw | inst_sw | inst_subu | inst_slt | inst_sltiu | 
                                                                  inst_slti | inst_xori | inst_sub | inst_sltu | inst_xor | 
                                                                  inst_nor | inst_srl | inst_srlv | inst_sra | inst_srav | 
                                                                  inst_mthi | inst_mtlo | inst_lbu | inst_jal);
    assign id_aluop_o[0]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_mflo | inst_sll | inst_ori | inst_lui | inst_sh | inst_subu |
                                                                  inst_addiu | inst_sltiu | inst_addu | inst_sltu | inst_multu | 
                                                                  inst_or | inst_nor | inst_sllv | inst_sra | inst_srav | inst_mtlo | 
                                                                  inst_lh | inst_lbu | inst_jr | inst_bne );

    // дͨ�üĴ���ʹ���ź�
    assign id_wreg_o       = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : ( inst_and | inst_mfhi | inst_mflo | inst_sll | inst_ori | 
                                                                  inst_lui | inst_lb | inst_lw | inst_add | inst_subu | inst_slt | 
                                                                  inst_addiu | inst_sltiu |  inst_addi | inst_slti | inst_andi | 
                                                                  inst_xori | inst_addu | inst_sub | inst_sltu | inst_or | inst_nor | 
                                                                  inst_xor | inst_srl | inst_srlv | inst_sllv | inst_sra |
                                                                  inst_srav | inst_lbu | inst_lh | inst_lhu | inst_jal);
    
    //дHILO�Ĵ���ʹ���ź�
    assign id_whilo_o = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_mult | inst_multu | inst_mthi | inst_mtlo);
    
    //��λʹ���źţ�sa�ֶΣ�
    wire shift = inst_sll | inst_sra | inst_srl ;
    
    //������ʹ���ź�
    wire immsel = inst_ori | inst_lui | inst_lw | inst_lb | inst_sb | inst_sh | inst_sw | inst_addiu | inst_sltiu | 
                   inst_addi | inst_slti | inst_andi | inst_xori | inst_lbu | inst_lh | inst_lhu;
    
    //Ŀ�ļĴ���ѡ���ź�(rt����rd)
    wire rtsel = inst_ori | inst_lui | inst_lb | inst_lw | inst_addiu | inst_sltiu | inst_addi | inst_slti | inst_andi | inst_xori | 
                  inst_lbu | inst_lh | inst_lhu;
    
    //������չʹ���ź�
    wire sext = inst_lb | inst_lw | inst_sb | inst_sh | inst_sw | inst_addiu | inst_sltiu | inst_addi | inst_slti | inst_lbu | 
                 inst_lh | inst_lhu;
    
    //���ظ߰���ʹ���ź�
    wire upper = inst_lui;
    
    //�洢�����Ĵ���ʹ���ź�
    assign id_mreg_o = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_lb | inst_lw | inst_lh | inst_lbu | inst_lhu);
    
    // ��ͨ�üĴ����Ѷ˿�1ʹ���ź�
    assign rreg1 = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_and | inst_mult | inst_ori | inst_lb | inst_lw | inst_sb | inst_sh | 
                                                        inst_sw | inst_add | inst_subu | inst_sltiu | inst_slt | inst_addiu | 
                                                        inst_addi | inst_slti | inst_xori | inst_andi | inst_addu | inst_sub | 
                                                        inst_multu | inst_sltu | inst_or | inst_xor | inst_nor | inst_sllv | 
                                                        inst_srlv | inst_srav | inst_mthi | inst_mtlo | inst_lbu | inst_lh |
                                                        inst_lhu | inst_jr | inst_beq | inst_bne );
    // ��ͨ�üĴ����Ѷ��˿�2ʹ���ź�
    assign rreg2 = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_and | inst_mult | inst_sll | inst_sb | inst_sh | inst_sw | 
                                                        inst_add | inst_subu | inst_slt | inst_addu | inst_sub | inst_multu | 
                                                        inst_sltu | inst_or | inst_xor | inst_nor | inst_sllv | inst_srl | 
                                                        inst_srlv | inst_sra | inst_srav | inst_beq | inst_bne);
    
    /*------------------------------------------------------------------------------*/

    // ��ͨ�üĴ����Ѷ˿�1�ĵ�ַΪrs�ֶΣ����˿�2�ĵ�ַΪrt�ֶ�
    assign ra1   = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : rs;
    assign ra2   = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : rt;
    
    //���ָ���������Ҫ��������
    wire [31:0] imm_ext = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : 
                           (upper == `UPPER_ENABLE) ? (imm << 16) :
                           (sext == `SIGNED_EXT) ? {{16{imm[15]}}, imm} : {{16{1'b0}}, imm};       
/*---------------------------------------ת��ָ���޸�begin---------------------------*/ 
    wire jal = inst_jal;
     // ��ô�д��Ŀ�ļĴ����ĵ�ַ��rt��rd��������31�żĴ�����
    assign id_wa_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : 
                     (rtsel == `RT_ENABLE) ? rt : 
                     (jal == `TRUE_V ) ?  5'b11111 : rd;
       
/*---------------------------------------ת��ָ���޸�end-----------------------------*/                        
   
    /*-----------------------------------------�����������begin--------------------------------*/
    wire [1:0] fwrd1 = (cpu_rst_n == `RST_ENABLE) ? 2'b00 : 
                        (exe2id_wreg == `WRITE_ENABLE && exe2id_wa == ra1 && rreg1 == `READ_ENABLE) ? 2'b01 :
                        (mem2id_wreg == `WRITE_ENABLE && mem2id_wa == ra1 && rreg1 == `READ_ENABLE) ? 2'b10 :
                        (rreg1 == `READ_ENABLE) ? 2'b11 : 2'b00;
    
    wire [1:0] fwrd2 = (cpu_rst_n == `RST_ENABLE) ? 2'b00 : 
                        (exe2id_wreg == `WRITE_ENABLE && exe2id_wa == ra2 && rreg2 == `READ_ENABLE) ? 2'b01 :
                        (mem2id_wreg == `WRITE_ENABLE && mem2id_wa == ra2 && rreg2 == `READ_ENABLE) ? 2'b10 :
                        (rreg1 == `READ_ENABLE) ? 2'b11 : 2'b00;
    /*-----------------------------------------�����������end--------------------------------*/
    
    /*-----------------------------------------��������޸�begin------------------------------*/
    //��÷ô�׶�Ҫ�������ݴ洢��������(��������ִ�н׶ε����ݡ��������Էô�׶�ǰ�Ƶ����ݡ�Ҳ��������ͨ�üĴ����ѵ�rd2)
    assign id_din_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                      (fwrd2 == 2'b01) ? exe2id_wd :
                      (fwrd2 == 2'b10) ? mem2id_wd : 
                      (fwrd2 == 2'b11) ? rd2 : `ZERO_WORD;         
    
    // ���Դ������1��Դ������1��������λλ��������ִ�н׶�ǰ�Ƶ����ݡ����Էô�׶�ǰ�Ƶ����ݡ�Ҳ��������ͨ�üĴ����ѵĶ��˿�1
    assign id_src1_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                       (shift == `SHIFT_ENABLE)   ? {27'b0, sa} :
                       (fwrd1 == 2'b01) ? exe2id_wd :
                       (fwrd1 == 2'b10) ? mem2id_wd :  
                       (fwrd1 == 2'b11) ? rd1 : `ZERO_WORD;
    
    // ���Դ������2�����immsel�ź���Ч����Դ������1Ϊ������������Ϊ�Ӷ�ͨ�üĴ����Ѷ˿�2��õ�����
    assign id_src2_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                       (immsel == `IMM_ENABLE) ? imm_ext :
                       (fwrd2 == 2'b01) ? exe2id_wd : 
                       (fwrd2 == 2'b10) ? mem2id_wd :
                       (fwrd2 == 2'b11) ? rd2 : `ZERO_WORD;
    /*-----------------------------------------��������޸�end--------------------------------*/
    
/*----------------------------------------ת��ָ�����begin-------------------------------*/
    //���ɼ���ת�Ƶ�ַ�����ź�
    wire [`INST_ADDR_BUS] pc_plus_8 = pc_plus_4 + 4;
    wire [`JUMP_BUS] instr_index = id_inst[25 : 0];
    wire [`INST_ADDR_BUS] imm_jump = {{14{imm[15]}}, imm, 2'b00};
    
    //���ת�Ƶ�ַ
    assign jump_addr_1 = {pc_plus_4[31:8], instr_index, 2'b00};
    assign jump_addr_2 = id_src1_o;
    assign jump_addr_3 = pc_plus_4 + imm_jump;
    
    //�����ӳ�����õķ��ص�ַ
    assign ret_addr = pc_plus_8;
    
    wire equ = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : 
                (inst_beq) ? (id_src1_o == id_src2_o) : 
                (inst_bne) ? (id_src1_o != id_src2_o) : 1'b0;
                
    assign jtsel[1] = inst_jr | inst_beq & equ | inst_bne & equ;
    assign jtsel[0] = inst_j | inst_jal | inst_beq & equ | inst_bne & equ;
/*----------------------------------------ת��ָ�����end---------------------------------*/
    
endmodule
