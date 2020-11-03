`include "defines.v"

module id_stage(
    input  wire                     cpu_rst_n,
    
    // 从取指阶段获得的PC值
    input  wire [`INST_ADDR_BUS]    id_pc_i,

    // 从指令存储器读出的指令字
    input  wire [`INST_BUS     ]    id_inst_i,

    // 从通用寄存器堆读出的数据 
    input  wire [`REG_BUS      ]    rd1,
    input  wire [`REG_BUS      ]    rd2,
    
    /*------------------------------消除数据相关begin--------------------------------*/
    //从执行阶段获得的写回信号
    input  wire                     exe2id_wreg,//写寄存器使能信号
    input  wire [`REG_ADDR_BUS]     exe2id_wa,//写寄存器地址
    input  wire [`INST_BUS]         exe2id_wd,//写寄存器数据
    
    //从访存阶段获得的写回信号
    input  wire                     mem2id_wreg,
    input  wire [`REG_ADDR_BUS]     mem2id_wa,
    input  wire [`INST_BUS]         mem2id_wd,
    /*------------------------------消除数据相关end--------------------------------*/
    /*------------------------------转移指令添加begin------------------------------*/
    input  wire [`INST_ADDR_BUS]    pc_plus_4,
    
    output wire [`INST_ADDR_BUS]    jump_addr_1,
    output wire [`INST_ADDR_BUS]    jump_addr_2,
    output wire [`INST_ADDR_BUS]    jump_addr_3,
    output wire [`JTSEL_BUS]        jtsel,
    output wire [`INST_ADDR_BUS]    ret_addr,
    /*------------------------------转移指令添加end--------------------------------*/
    
      
    // 送至执行阶段的译码信息
    output wire [`ALUTYPE_BUS  ]    id_alutype_o,
    output wire [`ALUOP_BUS    ]    id_aluop_o,
    output wire                     id_whilo_o,//乘法标识位
    output wire                     id_mreg_o,// 存储器到寄存器的使能信号
    output wire [`REG_ADDR_BUS ]    id_wa_o,//写入目的寄存器的地址
    output wire                     id_wreg_o,
    output wire [`REG_BUS]          id_din_o,// 写入内存的数据

    // 送至执行阶段的源操作数1、源操作数2
    output wire [`REG_BUS      ]    id_src1_o,
    output wire [`REG_BUS      ]    id_src2_o,
      
    // 送至读通用寄存器堆端口的使能和地址
    output wire                     rreg1,
    output wire [`REG_ADDR_BUS ]    ra1,
    output wire                     rreg2,
    output wire [`REG_ADDR_BUS ]    ra2
    );
    
    // 根据小端模式组织指令字
    wire [`INST_BUS] id_inst = {id_inst_i[7:0], id_inst_i[15:8], id_inst_i[23:16], id_inst_i[31:24]};

    // 提取指令字中各个字段的信息
    wire [5 :0] op   = id_inst[31:26];
    wire [5 :0] func = id_inst[5 : 0];
    wire [4 :0] rd   = id_inst[15:11];
    wire [4 :0] rs   = id_inst[25:21];
    wire [4 :0] rt   = id_inst[20:16];
    wire [4 :0] sa   = id_inst[10: 6];
    wire [15:0] imm  = id_inst[15: 0]; 

    /*-------------------- 第一级译码逻辑：确定当前需要译码的指令 --------------------*/
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
    wire inst_sltiu = ~op[5] & ~op[4] & op[3] & ~op[2] & op[1] & op[0]; //16: sltiu(imm有符号扩展至32位进行无符号比较)
    wire inst_addi = ~op[5] & ~op[4] & op[3] & ~op[2] & ~op[1] & ~op[0]; //17: addi(加立即数，可触发溢出异常)
    wire inst_slti = ~op[5] & ~op[4] & op[3] & ~op[2] & op[1] & ~op[0]; //18: slti(imm有符号扩展有符号比较)
    wire inst_andi = ~op[5] & ~op[4] & op[3] & op[2] & ~op[1] & ~op[0]; //19: andi(imm无符号扩展)
    wire inst_xori = ~op[5] & ~op[4] & op[3] & op[2] & op[1] & ~op[0]; //20 : xori(imm无符号扩展)
    wire inst_addu = inst_reg & func[5] & ~func[4] & ~func[3] & ~func[2] & ~func[1] & func[0]; //21: addu(加法，不触发溢出异常)
    wire inst_sub = inst_reg & func[5] & ~func[4] & ~func[3] & ~func[2] & func[1] & ~func[0]; //22: sub(减法， 触发溢出异常)
    wire inst_sltu = inst_reg & func[5] & ~func[4] & func[3] & ~func[2] & func[1] & func[0];//23: sltu(rs和rt进行无符号比较)
    wire inst_multu = inst_reg & ~func[5] & func[4] & func[3] & ~func[2] & ~func[1] & func[0]; //24: multu(无符号乘法)
    wire inst_xor = inst_reg & func[5] & ~func[4] & ~func[3] & func[2] & func[1] & ~func[0]; //25: xor(按位异或)
    wire inst_or = inst_reg & func[5] & ~func[4] & ~func[3] & func[2] & ~func[1] & func[0]; //26: or(按位或)
    wire inst_nor = inst_reg & func[5] & ~func[4] & ~func[3] & func[2] & func[1] & func[0]; //27: nor(按位或非)
    wire inst_sllv = inst_reg & ~func[5] & ~func[4] & ~func[3] & func[2] & ~func[1] & ~func[0];//28: sllv(逻辑左移，移位位数为rs的低5位)
    wire inst_sra = inst_reg & ~func[5] & ~func[4] & ~func[3] & ~func[2] & func[1] & func[0];//29: sra(算术右移)
    wire inst_srav = inst_reg & ~func[5] & ~func[4] & ~func[3] & func[2] & func[1] & func[0];//30: srav(算术右移，移位位数来自rs的低五位)
    wire inst_srl = inst_reg & ~func[5] & ~func[4] & ~func[3] & ~func[2] & func[1] & ~func[0];//31: srl(逻辑右移)
    wire inst_srlv = inst_reg & ~func[5] & ~func[4] & ~func[3] & func[2] & func[1] & ~func[0]; //32: srlv(逻辑右移，移位位数来自rs的低五位)
    wire inst_mthi = inst_reg & ~func[5] & func[4] & ~func[3] & ~func[2] & ~func[1] & func[0]; //33: mthi(rs移至HI寄存器)
    wire inst_mtlo = inst_reg & ~func[5] & func[4] & ~func[3] & ~func[2] & func[1] & func[0]; //34: mtlo(rs移至LO寄存器)
    wire inst_lbu = op[5] & ~op[4] & ~op[3] & op[2] & ~op[1] & ~op[0]; //35: lbu(rs + 立即数有符号扩展作为访存地址，无符号扩展byte)
    wire inst_lh = op[5] & ~op[4] & ~op[3] & ~op[2] & ~op[1] & op[0]; //36: lh(加载两字节符号扩展)
    wire inst_lhu = op[5] & ~op[4] & ~op[3] & op[2] & ~op[1] & op[0]; //37: lhu(加载两个字节无符号扩展)
    /*----------------------------转移指令添加begin-------------------------------*/
    wire inst_j = ~op[5] & ~op[4] & ~op[3] & ~op[2] & op[1] & ~op[0]; //38: j(PC无条件跳转PC+4高四位和instr_index左移两位拼接而成的指令处)
    wire inst_jal = ~op[5] & ~op[4] & ~op[3] & ~op[2] & op[1] & op[0]; //39: jal(同j,但是要把PC+8存到$ra中)
    wire inst_jr = inst_reg & ~func[5] & ~func[4] & func[3] & ~func[2] & ~func[1] & ~func[0]; //40: jr(无条件转移，转移目标地址为寄存器rs的值)
    wire inst_beq = ~op[5] & ~op[4] & ~op[3] & op[2] & ~op[1] & ~op[0]; //41: beq(如果rs=rt中的值，则跳转到PC + 4 + imm << 2)
    wire inst_bne = ~op[5] & ~op[4] & ~op[3] & op[2] & ~op[1] & op[0]; //42: bne(如果rs!=rt中的值，则跳转到PC + 4 + imm << 2)
    /*----------------------------转移指令添加end---------------------------------*/

    /*-------------------- 第二级译码逻辑：生成具体控制信号 --------------------*/
    // 操作类型alutype
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

    // 内部操作码aluop
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

    // 写通用寄存器使能信号
    assign id_wreg_o       = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : ( inst_and | inst_mfhi | inst_mflo | inst_sll | inst_ori | 
                                                                  inst_lui | inst_lb | inst_lw | inst_add | inst_subu | inst_slt | 
                                                                  inst_addiu | inst_sltiu |  inst_addi | inst_slti | inst_andi | 
                                                                  inst_xori | inst_addu | inst_sub | inst_sltu | inst_or | inst_nor | 
                                                                  inst_xor | inst_srl | inst_srlv | inst_sllv | inst_sra |
                                                                  inst_srav | inst_lbu | inst_lh | inst_lhu | inst_jal);
    
    //写HILO寄存器使能信号
    assign id_whilo_o = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_mult | inst_multu | inst_mthi | inst_mtlo);
    
    //移位使能信号（sa字段）
    wire shift = inst_sll | inst_sra | inst_srl ;
    
    //立即数使能信号
    wire immsel = inst_ori | inst_lui | inst_lw | inst_lb | inst_sb | inst_sh | inst_sw | inst_addiu | inst_sltiu | 
                   inst_addi | inst_slti | inst_andi | inst_xori | inst_lbu | inst_lh | inst_lhu;
    
    //目的寄存器选择信号(rt还是rd)
    wire rtsel = inst_ori | inst_lui | inst_lb | inst_lw | inst_addiu | inst_sltiu | inst_addi | inst_slti | inst_andi | inst_xori | 
                  inst_lbu | inst_lh | inst_lhu;
    
    //符号扩展使能信号
    wire sext = inst_lb | inst_lw | inst_sb | inst_sh | inst_sw | inst_addiu | inst_sltiu | inst_addi | inst_slti | inst_lbu | 
                 inst_lh | inst_lhu;
    
    //加载高半字使能信号
    wire upper = inst_lui;
    
    //存储器到寄存器使能信号
    assign id_mreg_o = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_lb | inst_lw | inst_lh | inst_lbu | inst_lhu);
    
    // 读通用寄存器堆端口1使能信号
    assign rreg1 = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_and | inst_mult | inst_ori | inst_lb | inst_lw | inst_sb | inst_sh | 
                                                        inst_sw | inst_add | inst_subu | inst_sltiu | inst_slt | inst_addiu | 
                                                        inst_addi | inst_slti | inst_xori | inst_andi | inst_addu | inst_sub | 
                                                        inst_multu | inst_sltu | inst_or | inst_xor | inst_nor | inst_sllv | 
                                                        inst_srlv | inst_srav | inst_mthi | inst_mtlo | inst_lbu | inst_lh |
                                                        inst_lhu | inst_jr | inst_beq | inst_bne );
    // 读通用寄存器堆读端口2使能信号
    assign rreg2 = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_and | inst_mult | inst_sll | inst_sb | inst_sh | inst_sw | 
                                                        inst_add | inst_subu | inst_slt | inst_addu | inst_sub | inst_multu | 
                                                        inst_sltu | inst_or | inst_xor | inst_nor | inst_sllv | inst_srl | 
                                                        inst_srlv | inst_sra | inst_srav | inst_beq | inst_bne);
    
    /*------------------------------------------------------------------------------*/

    // 读通用寄存器堆端口1的地址为rs字段，读端口2的地址为rt字段
    assign ra1   = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : rs;
    assign ra2   = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : rt;
    
    //获得指令操作所需要的立即数
    wire [31:0] imm_ext = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : 
                           (upper == `UPPER_ENABLE) ? (imm << 16) :
                           (sext == `SIGNED_EXT) ? {{16{imm[15]}}, imm} : {{16{1'b0}}, imm};       
/*---------------------------------------转移指令修改begin---------------------------*/ 
    wire jal = inst_jal;
     // 获得待写入目的寄存器的地址（rt或rd还可能是31号寄存器）
    assign id_wa_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : 
                     (rtsel == `RT_ENABLE) ? rt : 
                     (jal == `TRUE_V ) ?  5'b11111 : rd;
       
/*---------------------------------------转移指令修改end-----------------------------*/                        
   
    /*-----------------------------------------消除数据相关begin--------------------------------*/
    wire [1:0] fwrd1 = (cpu_rst_n == `RST_ENABLE) ? 2'b00 : 
                        (exe2id_wreg == `WRITE_ENABLE && exe2id_wa == ra1 && rreg1 == `READ_ENABLE) ? 2'b01 :
                        (mem2id_wreg == `WRITE_ENABLE && mem2id_wa == ra1 && rreg1 == `READ_ENABLE) ? 2'b10 :
                        (rreg1 == `READ_ENABLE) ? 2'b11 : 2'b00;
    
    wire [1:0] fwrd2 = (cpu_rst_n == `RST_ENABLE) ? 2'b00 : 
                        (exe2id_wreg == `WRITE_ENABLE && exe2id_wa == ra2 && rreg2 == `READ_ENABLE) ? 2'b01 :
                        (mem2id_wreg == `WRITE_ENABLE && mem2id_wa == ra2 && rreg2 == `READ_ENABLE) ? 2'b10 :
                        (rreg1 == `READ_ENABLE) ? 2'b11 : 2'b00;
    /*-----------------------------------------消除数据相关end--------------------------------*/
    
    /*-----------------------------------------数据相关修改begin------------------------------*/
    //获得访存阶段要存入数据存储器的数据(可能来自执行阶段的数据、可能来自访存阶段前推的数据、也可能来自通用寄存器堆的rd2)
    assign id_din_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                      (fwrd2 == 2'b01) ? exe2id_wd :
                      (fwrd2 == 2'b10) ? mem2id_wd : 
                      (fwrd2 == 2'b11) ? rd2 : `ZERO_WORD;         
    
    // 获得源操作数1。源操作数1可能是移位位数、来自执行阶段前推的数据、来自访存阶段前推的数据、也可能来自通用寄存器堆的读端口1
    assign id_src1_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                       (shift == `SHIFT_ENABLE)   ? {27'b0, sa} :
                       (fwrd1 == 2'b01) ? exe2id_wd :
                       (fwrd1 == 2'b10) ? mem2id_wd :  
                       (fwrd1 == 2'b11) ? rd1 : `ZERO_WORD;
    
    // 获得源操作数2。如果immsel信号有效，则源操作数1为立即数；否则为从读通用寄存器堆端口2获得的数据
    assign id_src2_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                       (immsel == `IMM_ENABLE) ? imm_ext :
                       (fwrd2 == 2'b01) ? exe2id_wd : 
                       (fwrd2 == 2'b10) ? mem2id_wd :
                       (fwrd2 == 2'b11) ? rd2 : `ZERO_WORD;
    /*-----------------------------------------数据相关修改end--------------------------------*/
    
/*----------------------------------------转移指令添加begin-------------------------------*/
    //生成计算转移地址所需信号
    wire [`INST_ADDR_BUS] pc_plus_8 = pc_plus_4 + 4;
    wire [`JUMP_BUS] instr_index = id_inst[25 : 0];
    wire [`INST_ADDR_BUS] imm_jump = {{14{imm[15]}}, imm, 2'b00};
    
    //获得转移地址
    assign jump_addr_1 = {pc_plus_4[31:8], instr_index, 2'b00};
    assign jump_addr_2 = id_src1_o;
    assign jump_addr_3 = pc_plus_4 + imm_jump;
    
    //生成子程序调用的返回地址
    assign ret_addr = pc_plus_8;
    
    wire equ = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : 
                (inst_beq) ? (id_src1_o == id_src2_o) : 
                (inst_bne) ? (id_src1_o != id_src2_o) : 1'b0;
                
    assign jtsel[1] = inst_jr | inst_beq & equ | inst_bne & equ;
    assign jtsel[0] = inst_j | inst_jal | inst_beq & equ | inst_bne & equ;
/*----------------------------------------转移指令添加end---------------------------------*/
    
endmodule
