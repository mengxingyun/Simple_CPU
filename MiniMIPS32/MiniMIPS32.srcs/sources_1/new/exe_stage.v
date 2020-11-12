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
    input  wire                    exe_mreg_i,
    input  wire [`REG_BUS]         exe_din_i,
    
    // ��hilo�Ĵ�����õ�����       
    input wire [`REG_BUS]          hi_i,
    input wire [`REG_BUS]          lo_i,     
    
    /*------------------------------------------�����������begin-------------------------------*/
    //�ӷô�׶λ�õ�HI��LO�Ĵ�����ֵ
    input wire                     mem2exe_whilo,
    input wire [`DOUBLE_REG_BUS]   mem2exe_hilo,
    
    //��д�ؽ׶λ�õ�HI��LO�Ĵ�����ֵ
    input wire                     wb2exe_whilo,
    input wire [`DOUBLE_REG_BUS]   wb2exe_hilo,
    /*------------------------------------------�����������end---------------------------------*/
    input wire [`INST_ADDR_BUS]    ret_addr,
    
    /*-------------------------------------��ˮ����ͣbegin----------------------*/
    //������ʱ�ӣ����ڳ�������
    input wire                    cpu_clk_50M,
    //ִ�н׶η�������ͣ�����ź�
    output wire                   stallreq_exe,
    /*-------------------------------------��ˮ����ͣend------------------------*/

    // ����ִ�н׶ε���Ϣ
    output wire [`ALUOP_BUS	    ] 	exe_aluop_o,
    output wire [`REG_ADDR_BUS 	] 	exe_wa_o,
    output wire 					exe_wreg_o,
    output wire [`REG_BUS 		] 	exe_wd_o,
    output wire                    exe_whilo_o,//�˷�flag
    output wire[`DOUBLE_REG_BUS]   exe_hilo_o,//�˷����
    output wire                    exe_mreg_o,
    output wire[`REG_BUS]          exe_din_o
    );

    // ֱ�Ӵ�����һ�׶�
    assign exe_aluop_o = (cpu_rst_n == `RST_ENABLE) ? 8'b0 : exe_aluop_i;
    assign exe_whilo_o = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : exe_whilo_i;
    assign exe_mreg_o = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : exe_mreg_i;
    assign exe_din_o = (cpu_rst_n == `RST_ENABLE) ? 32'b0 : exe_din_i;
    
    wire [`REG_BUS       ]      logicres;       // �����߼�����Ľ��
    wire [`DOUBLE_REG_BUS       ]      sign_mulres; //�����з��ų˷�������
    wire [`DOUBLE_REG_BUS       ]      unsign_mulres; //�����޷��ų˷�������
    wire [`REG_BUS]             hi_t;          //����HI�Ĵ���������ֵ
    wire [`REG_BUS]             lo_t;          //����LO�Ĵ���������ֵ
    wire [`REG_BUS]             moveres;       //�����ƶ������Ľ��
    wire [`REG_BUS]             shiftres;      //������λ����Ľ��
    wire [`REG_BUS]             arithres;      //�������������Ľ��
    /*--------------------------------����ָ��begin---------------------------*/
    reg  [`DOUBLE_REG_BUS]      divres; //������������Ľ��
    /*--------------------------------����ָ��end-----------------------------*/
    
    // �����ڲ�������aluop�����߼�����
    assign logicres = (cpu_rst_n == `RST_ENABLE)  ? `ZERO_WORD : 
                      (exe_aluop_i == `MINIMIPS32_AND )  ? (exe_src1_i & exe_src2_i) : 
                      (exe_aluop_i == `MINIMIPS32_ORI )  ? (exe_src1_i | exe_src2_i) : 
                      (exe_aluop_i == `MINIMIPS32_XORI ) ? (exe_src1_i ^ exe_src2_i) : 
                      (exe_aluop_i == `MINIMIPS32_NOR ) ? ~(exe_src1_i | exe_src2_i) :
                      (exe_aluop_i == `MINIMIPS32_LUI )  ?  exe_src2_i : `ZERO_WORD;
            
    // �����ڲ�������aluop������������
    assign arithres = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                      (exe_aluop_i == `MINIMIPS32_LB) ? (exe_src1_i + exe_src2_i) : 
                      (exe_aluop_i == `MINIMIPS32_LW) ? (exe_src1_i + exe_src2_i) : 
                      (exe_aluop_i == `MINIMIPS32_LBU) ? (exe_src1_i + exe_src2_i) :
                      (exe_aluop_i == `MINIMIPS32_LH) ? (exe_src1_i + exe_src2_i) :
                      (exe_aluop_i == `MINIMIPS32_LHU) ? (exe_src1_i + exe_src2_i) :
                      (exe_aluop_i == `MINIMIPS32_SB) ? (exe_src1_i + exe_src2_i) :
                      (exe_aluop_i == `MINIMIPS32_SH) ? (exe_src1_i + exe_src2_i) :
                      (exe_aluop_i == `MINIMIPS32_SW) ? (exe_src1_i + exe_src2_i) :
                      (exe_aluop_i == `MINIMIPS32_ADD) ? (exe_src1_i + exe_src2_i) : 
                      (exe_aluop_i == `MINIMIPS32_SUBU) ? (exe_src1_i + ~exe_src2_i + 1) : 
                      (exe_aluop_i == `MINIMIPS32_SUB) ? (exe_src1_i + ~exe_src2_i + 1) : 
                      (exe_aluop_i == `MINIMIPS32_SLT) ? (($signed(exe_src1_i) < $signed(exe_src2_i)) ? 32'b1 : 32'b0) : 
                      (exe_aluop_i == `MINIMIPS32_SLTIU) ? ((exe_src1_i < exe_src2_i) ? 32'b1 : 32'b0) : 
                      (exe_aluop_i == `MINIMIPS32_ADDIU) ? (exe_src1_i + exe_src2_i) : `ZERO_WORD;
    
    // �����ڲ�������aluop������λ����
    assign shiftres = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : 
                      (exe_aluop_i == `MINIMIPS32_SLL) ? (exe_src2_i << exe_src1_i) : 
                      (exe_aluop_i == `MINIMIPS32_SRL) ? (exe_src2_i >> exe_src1_i) :
                      (exe_aluop_i == `MINIMIPS32_SRA) ? (({32{exe_src2_i[31]}} << (6'd32-{1'b0, exe_src1_i[4:0]})) | exe_src2_i >> exe_src1_i[4:0]) : `ZERO_WORD;
    
    // �����ڲ�������aluop���������ƶ����õ����µ�HI��LO�Ĵ�����ֵ
    /*-------------------------------------------��������޸�begin---------------------------------*/
    assign hi_t = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                  (mem2exe_whilo == `WRITE_ENABLE) ? mem2exe_hilo[63:32] :
                  (wb2exe_whilo == `WRITE_ENABLE) ? wb2exe_hilo[63:32] : hi_i;
    assign lo_t = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : 
                  (mem2exe_whilo == `WRITE_ENABLE) ? mem2exe_hilo[31:0] :
                  (wb2exe_whilo == `WRITE_ENABLE) ? wb2exe_hilo[31:0] : lo_i;
   /*--------------------------------------------��������޸�end---------------------------------*/
                  
    assign moveres = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : 
                     (exe_aluop_i == `MINIMIPS32_MFHI) ? hi_t :
                     (exe_aluop_i == `MINIMIPS32_MFLO) ? lo_t : `ZERO_WORD;
    
   /*-------------------------------------����ָ��begin------------------------------------------*/
   wire                           signed_div_i;
   wire [`REG_BUS]                div_opdata1;
   wire [`REG_BUS]                div_opdata2;
   wire                           div_start; //�������㿪ʼ�ź�
   reg                            div_ready; //������������ź�
   
   assign stallreq_exe = (cpu_rst_n == `RST_ENABLE) ? `NOSTOP : 
                         ((exe_aluop_i == `MINIMIPS32_DIV) && (div_ready == `DIV_NOT_READY)) ? `STOP : 
                         ((exe_aluop_i == `MINIMIPS32_DIVU) && (div_ready == `DIV_NOT_READY)) ? `STOP : `NOSTOP; //�ǳ���ָ���������δ����������ͣ�ź�
   
   assign div_opdata1 = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                        (exe_aluop_i == `MINIMIPS32_DIV || exe_aluop_i == `MINIMIPS32_DIVU) ? exe_src1_i : `ZERO_WORD;
   
   assign div_opdata2 = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                        (exe_aluop_i == `MINIMIPS32_DIV || exe_aluop_i == `MINIMIPS32_DIVU) ? exe_src2_i : `ZERO_WORD;
   
   assign div_start = (cpu_rst_n == `RST_ENABLE) ? `DIV_STOP : 
                      ((exe_aluop_i == `MINIMIPS32_DIV) && (div_ready == `DIV_NOT_READY)) ? `DIV_START : 
                      ((exe_aluop_i == `MINIMIPS32_DIVU) && (div_ready == `DIV_NOT_READY)) ? `DIV_START : `DIV_STOP;//�ǳ���ָ���ҳ���δ��������ô�����Ѿ���ʼ
                      
   assign signed_div_i = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                         (exe_aluop_i == `MINIMIPS32_DIV) ? 1'b1 : 
                         (exe_aluop_i == `MINIMIPS32_DIVU) ? 1'b0 : 1'b0;
                         
   wire [34:0]                                 div_temp;
   wire [34:0]                                 div_temp0;
   wire [34:0]                                 div_temp1;
   wire [34:0]                                 div_temp2;
   wire [34:0]                                 div_temp3;
   wire [1: 0]                                 mul_cnt;
   
   //��¼���̷������˼��֣�������16ʱ��ʾ���̷�������
   reg  [5: 0]                                  cnt;
   
   reg  [65:0]                                  dividend;
   reg  [1: 0]                                  state;
   reg  [33:0]                                  divisor;
   reg  [31:0]                                  temp_op1;
   reg  [31:0]                                  temp_op2;
   
   wire [33:0]                                  divisor_temp;
   wire [33:0]                                  divisor2;
   wire [33:0]                                  divisor3;
   
   assign  divisor_temp = temp_op2; //������1��
   assign  divisor2 = divisor_temp << 1; // ������2��
   assign  divisor3 = divisor2 + divisor; //������3��
   
   //diviend�ĵ�32λ������Ǳ��������м�������k�ε���������ʱ��diviend[k:0]����ľ��ǵ�ǰ
  //�õ����м�����dividend[32:k+1]����ľ��Ǳ������л�û�в�������Ķ����ݣ�dividend��32λ��ÿ�ε����ı�����
   assign div_temp0 = {1'b000, dividend[63:32]} - {1'b000, `ZERO_WORD};
   assign div_temp1 = {1'b000, dividend[63:32]} - {1'b0, divisor};
   assign div_temp2 = {1'b000, dividend[63:32]} - {1'b0, divisor2};
   assign div_temp3 = {1'b000, dividend[63:32]} - {1'b0, divisor3};
   
   assign div_temp = (div_temp3[34] == 1'b0) ? div_temp3 : 
                     (div_temp2[34] == 1'b0) ? div_temp2 : div_temp1;
    
   assign mul_cnt = (div_temp3[34] == 1'b0) ? 2'b11 : 
                    (div_temp2[34] == 1'b0) ? 2'b10 : 2'b01;
   
   always @(posedge cpu_clk_50M) begin
        if(cpu_rst_n == `RST_ENABLE) begin
            state  <=   `DIV_FREE;
            div_ready <= `DIV_NOT_READY;
            divres    <= {`ZERO_WORD, `ZERO_WORD};
        end else begin
        case (state)
            `DIV_FREE: begin
                if(div_start == `DIV_START) begin
                    if(div_opdata2 == `ZERO_WORD) begin
                        state <= `DIV_BY_ZERO;
                    end else begin
                        state <= `DIV_ON;
                        cnt <= 6'b000000;
                        if(signed_div_i == 1'b1 && div_opdata1[31] == 1'b1) begin //�з��ų���ȡ�����ľ���ֵ
                            temp_op1 = ~div_opdata1 + 1;
                        end else begin
                            temp_op1 = div_opdata1;
                        end
                        if(signed_div_i == 1'b1 && div_opdata2[31] == 1'b1) begin
                            temp_op2 = ~div_opdata2 + 1;
                        end else begin
                            temp_op2 = div_opdata2;
                        end
                        dividend <= {`ZERO_WORD, `ZERO_WORD};
                        dividend[31:0] <= temp_op1;
                        divisor <= temp_op2;
                    end
                end else begin//δ��ʼ��������
                    div_ready <= `DIV_NOT_READY;
                    divres <= {`ZERO_WORD, `ZERO_WORD};
                end
            end 
            
            `DIV_BY_ZERO: begin
                dividend <= {`ZERO_WORD, `ZERO_WORD};
                state <= `DIV_END;
            end
            
            `DIV_ON: begin
                if(cnt != 6'b100010) begin
                    if(div_temp[34] == 1'b1) begin
                        dividend <= {dividend[63:0], 2'b00};
                    end else begin
                        dividend <= {div_temp[31:0], dividend[31:0], mul_cnt};
                    end
                    cnt <= cnt + 2;
                end else begin
                    if((signed_div_i == 1'b1) && ((div_opdata1[31] ^ div_opdata2[31]) == 1'b1)) begin
                        dividend[31:0] <= (~dividend[31:0] + 1);
                    end
                    if((signed_div_i == 1'b1) && ((div_opdata1[31] ^ dividend[65]) == 1'b1)) begin
                        dividend[65: 34] <= (~dividend[65:34] + 1);
                    end
                    state <= `DIV_END;
                    cnt <= 6'b000000; //cnt��0
                end
            end
            
            `DIV_END: begin
                divres <= {dividend[65:34], dividend[31:0]};
                div_ready <= `DIV_READY;
                if(div_start == `DIV_STOP) begin
                    state <= `DIV_FREE;
                    div_ready <= `DIV_NOT_READY;
                    divres <= {`ZERO_WORD, `ZERO_WORD};
                end
            end
        endcase
        end
   end
   /*-------------------------------------����ָ��end--------------------------------------------*/
   
   // �����ڲ�������aluop���г˷����㣬ֱ��������һ���׶�
   assign sign_mulres = ($signed(exe_src1_i) * $signed(exe_src2_i));
   assign unsign_mulres = ($unsigned({1'b0,exe_src1_i}) * $unsigned({1'b0,exe_src2_i}));
   assign exe_hilo_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : //ʹ����aluopΪ0x14
                       (exe_aluop_i == `MINIMIPS32_MULT) ? sign_mulres : 
                       (exe_aluop_i == `MINIMIPS32_MULTU) ? unsign_mulres : 
                       (exe_aluop_i == `MINIMIPS32_DIV) ? divres : 
                       (exe_aluop_i == `MINIMIPS32_DIVU) ? divres : 
                       (exe_aluop_i == `MINIMIPS32_MTHI) ? {exe_src1_i, lo_t} : 
                       (exe_aluop_i == `MINIMIPS32_MTLO) ? {hi_t, exe_src1_i} : `ZERO_DWORD;

    assign exe_wa_o   = (cpu_rst_n   == `RST_ENABLE ) ? 5'b0 	 : exe_wa_i;
    assign exe_wreg_o = (cpu_rst_n   == `RST_ENABLE ) ? 1'b0 	 : exe_wreg_i;
    
    // ���ݲ�������alutypeȷ��ִ�н׶����յ����������ȿ����Ǵ�д��Ŀ�ļĴ��������ݣ�Ҳ�����Ƿ������ݴ洢���ĵ�ַ��
    assign exe_wd_o = (cpu_rst_n   == `RST_ENABLE ) ? `ZERO_WORD : 
                      (exe_alutype_i == `LOGIC    ) ? logicres  : 
                      (exe_alutype_i == `MOVE ) ? moveres : 
                      (exe_alutype_i == `SHIFT) ? shiftres : 
                      (exe_alutype_i == `ARITH) ? arithres : 
                      (exe_alutype_i == `JUMP) ? ret_addr : `ZERO_WORD;

endmodule