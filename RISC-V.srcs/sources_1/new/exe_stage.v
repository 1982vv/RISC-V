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
    input  wire                    exe_mreg_i,
    input  wire [`REG_BUS      ]   exe_din_i,

    // �����ô�׶ε���Ϣ
    output wire [`ALUOP_BUS	    ] 	exe_aluop_o,
    output wire [`REG_ADDR_BUS 	] 	exe_wa_o,
    output wire 					exe_wreg_o,
    output wire [`REG_BUS 		] 	exe_wd_o,
    output wire                     exe_mreg_o,
    output wire [`REG_BUS      ]    exe_din_o,
    
    //ת��ָ��
    input wire [`INST_ADDR_BUS ]    ret_addr,
    
    //��ͣ
    output wire                     stallreq_exe,
    input wire                      cpu_clk_50M
    );
     
    // ֱ�Ӵ�����һ�׶�
    assign exe_aluop_o = (cpu_rst_n == `RST_ENABLE) ? 8'b0 : exe_aluop_i;
    assign exe_mreg_o  = (cpu_rst_n == `RST_ENABLE) ? 1'b0: exe_mreg_i;
    assign exe_din_o   = (cpu_rst_n == `RST_ENABLE) ? 32'b0: exe_din_i;
    
    wire [`REG_BUS       ]      logicres;       // �����߼�����Ľ��
    wire [`REG_BUS       ]      shiftres;       // ������λ������
    wire [`REG_BUS       ]      moveres;        // �����ƶ������Ľ��
    wire [`REG_BUS       ]      arithres;       // �������������Ľ��
    wire [`REG_BUS       ]      memres;         // ����ô������ַ
    wire [`DOUBLE_REG_BUS]      mulres;         // ����˷������Ľ��
    wire [`DOUBLE_REG_BUS]      mulressu;         // ����˷������Ľ��
    wire [`DOUBLE_REG_BUS]      mulresu;         // ����˷������Ľ��
    reg  [`DOUBLE_REG_BUS]      divres;         // ������������Ľ��
    //��������
    wire                        signed_div_i;
    wire [`REG_BUS       ]      div_opdata1;
    wire [`REG_BUS       ]      div_opdata2;
    wire                        div_start;
    reg                         div_ready;
    
    assign div_opdata1 =(cpu_rst_n ==`RST_ENABLE)? `ZERO_WORD:
                        (exe_aluop_i== `RISCV_DIV || exe_aluop_i== `RISCV_REM) ? exe_src1_i:
                        (exe_aluop_i== `RISCV_DIVU || exe_aluop_i== `RISCV_REMU) ? exe_src1_i: `ZERO_WORD;
    assign div_opdata2=(cpu_rst_n == `RST_ENABLE)? `ZERO_WORD:
                       (exe_aluop_i== `RISCV_DIV || exe_aluop_i== `RISCV_REM)? exe_src2_i:
                       (exe_aluop_i== `RISCV_DIVU || exe_aluop_i== `RISCV_REMU) ? exe_src2_i: `ZERO_WORD;
    assign div_start =(cpu_rst_n == `RST_ENABLE)?`DIV_STOP:
                      ((exe_aluop_i== `RISCV_DIV || exe_aluop_i== `RISCV_REM) &&(div_ready == `DIV_NOT_READY))?`DIV_START: 
                      ((exe_aluop_i== `RISCV_DIVU || exe_aluop_i== `RISCV_REMU) &&(div_ready == `DIV_NOT_READY))?`DIV_START:`DIV_STOP;

    assign signed_div_i= (cpu_rst_n ==`RST_ENABLE)?1'b0:
                         (exe_aluop_i== `RISCV_DIV || exe_aluop_i== `RISCV_REM) ?1'b1: 1'b0;
    wire [34:0]         div_temp;
    wire [34:0]         div_temp0;
    wire [34:0]         div_temp1;
    wire [34:0]         div_temp2;
    wire [34:0]         div_temp3;
    wire [1:0]          mul_cnt;

    //��¼���̷������˼���,������16ʱ,��ʾ���̷�����
    reg  [5: 0]          cnt;
    
    reg [65: 0]         dividend;
    reg [1: 0]          state;
    reg [33:0]          divisor;
    reg [31:0]          temp_op1;
    reg [31: 0]         temp_op2;
    
    wire [33: 0]        divisor_temp;
    wire [33: 0]        divisor2;
    wire [33: 0]        divisor3;

    //dividend�ĵ�32λ������Ǳ��������м���,��k�ε���������ʱ��, dividend[k:]����ľ��ǵ�ǰ�õ����м��
    //�� dividend32k+1]����ľ��Ǳ������л�û�в������������, dividend��32λ��ÿ�δ�ʱ�ı�����
    assign divisor2=divisor+divisor;
    assign divisor3=divisor2+divisor;
    assign div_temp0 ={1'b000,dividend[63:32]}-{1'b000,`ZERO_WORD};//���������뱻������0�����
    assign div_temp1={1'b000,dividend[63:32]}-{1'b0,divisor};   //���������뱻������1�����
    assign div_temp2={1'b000,dividend[63:32]}-{1'b0,divisor2};  //���������뱻������2�����
    assign div_temp3={1'b000,dividend[63:32]}-{1'b0,divisor3};  //���������뱻������3�����

    assign div_temp =(div_temp3[34]== 1'b0 )? div_temp3:
                     (div_temp2[34] == 1'b0 )? div_temp2 : div_temp1;

    assign mul_cnt =(div_temp3[34] ==1'b0 )? 2'b11:
                    (div_temp2[34]==1'b0)? 2'b10:2'b01;
                    
    always @(posedge cpu_clk_50M)begin
    if (cpu_rst_n ==`RST_ENABLE) begin
        state       <= `DIV_FREE;
        div_ready   <= `DIV_NOT_READY;
        divres      <=  {`ZERO_WORD, `ZERO_WORD};
    end else begin
    case (state)
    //��3�����:
    //(1)��ʼ��������,�������Ϊ0��ô�� DivBy Zero״̬
    //(2)��ʼ��������,�ҳ�����Ϊ0,��ô����Divn״̬,��ʼ��cntΪ0������з���
    //����,�ұ��������߳���Ϊ��,��ô�Ա��������߳����������Ĳ��롣�������浽
    //divisordividend��,�������������λ���浽�ĵ�32λ,׼�����е�һ�ε���
    //(3)û�н��г�������,����*
    `DIV_FREE:begin
        if(div_start == `DIV_START) begin
            if(div_opdata2 == `ZERO_WORD) begin //����Ϊ0
                state <= `DIV_BY_ZERO;
            end else begin                      //������Ϊ0
                state <= `DIV_ON;
                cnt <= 6'b000000;
                if(div_opdata1[31] == 1'b1 && signed_div_i) begin
                    temp_op1=~div_opdata1+1;    //ȡ�����Ĳ���
                end else begin
                    temp_op1 =div_opdata1;
                end
                if(div_opdata2[31]==1'b1 && signed_div_i) begin
                    temp_op2 =~div_opdata2+1;   //ȡ�����Ĳ���
                end else begin
                    temp_op2 =div_opdata2;
                end
                dividend <= {`ZERO_WORD, `ZERO_WORD};
                dividend[31:0] <=temp_op1;
                divisor  <= temp_op2;
            end
    end else begin                      //û�п�ʼ��������
        div_ready <= `DIV_NOT_READY;
        divres    <= {`ZERO_WORD,`ZERO_WORD};
    end 
    end
            //�������DivByZero״̬.��ôֱ�ӽ��� DivEnd״̬��������.���Ϊ0
    `DIV_BY_ZERO: begin          //DivByZero
             dividend <= {`ZERO_WORD, `ZERO_WORD};
             state    <= `DIV_END;
     end

    //(1)���cnt��Ϊ16��ô��ʾ���̷���û�н���,��ʱ���������� div tempΪ����ô��
    //   ��ѡ�������0:����������div_tempΪ��,��ô�˴�ѡ�������1 dividend�����λ
    //(2)���cntΪ16,��ô��ʾ���̷�����,������з��ų���,�ұ�����������һ��һ��,��
    //   ô�����̷��Ľ���������Ĳ���,�õ����յĽ��,�˴����̡�������Ҫ�������Ĳ�
    //   ���̱�����dividend�ĵ�32λ,����������dividen dDivEnd�ĸ�32λ.ͬʱ����״̬
    `DIV_ON: begin   //DivOn
            if(cnt!=6'b100010) begin //cnt��Ϊ16,ʾ���̷���û�н���
                if(div_temp[34]==1'b1)begin
                //��� divtemp[34]Ϊ1,(minuend-n-n)���Сddd��λ,�����ͽ���������
                //û�в�����������λ���뵽��һ��ѡ���ı�������,ͬʱ��0׷�ӵ��м���
                    dividend <={dividend[63:0], 2'b00};
                end else begin
                //���di_temp[34]Ϊ0,��ʾ(minuend--n)������ڵ���0,�������Ľ���뱻������û�в�����
                //�����λ���뵽��һ��ѡ���ı�������,ͬʱ��1׷�ӵ��м���
                    dividend <={div_temp[31:0], dividend[31:0], mul_cnt};
                end
                cnt <= cnt+2;
             end else begin  //���̷�����
                if((div_opdata1[31]^div_opdata2[31])==1'b1 && signed_div_i) begin
                    dividend[31:0] <= (~dividend[31:0]+1); //ȡ�����Ĳ���
                end
                if((div_opdata1[31]^dividend[65])== 1'b1  && signed_div_i) begin
                    dividend[65: 34] <=(~dividend[65: 34]+1);//ȡ�����Ĳ���
                end
                state <= `DIV_END; //���� DivEnd״̬
                cnt   <= 6'b000000; //cnt����
             end
        end
    
    `DIV_END: begin
        divres <={dividend[65: 34], dividend[31: 0]};
        div_ready <= `DIV_READY;
        if(div_start == `DIV_STOP) begin
             state     <= `DIV_FREE;
             div_ready <= `DIV_NOT_READY;
             divres    <= {`ZERO_WORD, `ZERO_WORD};
        end
    end
    endcase
    end
    end
    
    // �����ڲ�������aluop�����߼�����
    assign logicres=(cpu_rst_n ==`RST_ENABLE)? `ZERO_WORD:
    (exe_aluop_i == `RISCV_AND)? (exe_src1_i & exe_src2_i):
    (exe_aluop_i == `RISCV_OR)? (exe_src1_i | exe_src2_i):
    (exe_aluop_i == `RISCV_ORI)? (exe_src1_i | exe_src2_i):
    (exe_aluop_i == `RISCV_ANDI)? (exe_src1_i & exe_src2_i):
    (exe_aluop_i == `RISCV_XORI)? (exe_src1_i ^ exe_src2_i):
    (exe_aluop_i == `RISCV_XOR)? (exe_src1_i ^ exe_src2_i):
    (exe_aluop_i == `RISCV_LUI)? exe_src2_i : `ZERO_WORD;
    
    //�����ڲ�������aluop������λ����
    assign shiftres=(cpu_rst_n == `RST_ENABLE)? `ZERO_WORD:
    (exe_aluop_i == `RISCV_SLL)? (exe_src2_i << exe_src1_i[4:0]) :
    (exe_aluop_i == `RISCV_SRL)? (exe_src2_i >> exe_src1_i[4:0]) :
    (exe_aluop_i == `RISCV_SRA)? ( {32{exe_src2_i[31]}} << ( 6'd32 - {1'b0, exe_src1_i[4:0]} ) ) | ( exe_src2_i >> exe_src1_i[4:0] ) :
    (exe_aluop_i == `RISCV_SRLI)? (exe_src2_i >> exe_src1_i) :
    (exe_aluop_i == `RISCV_SRAI)? ( {32{exe_src2_i[31]}} << ( 6'd32 - {1'b0, exe_src1_i[4:0]} ) ) | ( exe_src2_i >> exe_src1_i[4:0] ) :
    (exe_aluop_i == `RISCV_SLLI)? (exe_src2_i << exe_src1_i) : `ZERO_WORD;

    //�����ڲ�������aluop���������ƶ�
     assign moveres =(cpu_rst_n ==`RST_ENABLE)? `ZERO_WORD: `ZERO_WORD;
     
      //�����ڲ� aluop��������г˷�����
     assign mulres=($signed(exe_src1_i)* $signed(exe_src2_i));
     assign mulressu={{32{exe_src1_i[31]}},exe_src1_i}* {{32{1'b0}},exe_src2_i};
     assign mulresu={{32{1'b0}},exe_src1_i}* {{32{1'b0}},exe_src2_i};
     

     //�����ڲ������� aluop������������
     assign arithres =(cpu_rst_n ==`RST_ENABLE)? `ZERO_WORD:
      (exe_aluop_i == `RISCV_ADD) ?(exe_src1_i+ exe_src2_i):
      (exe_aluop_i == `RISCV_ADDI) ?(exe_src1_i+ exe_src2_i):
      (exe_aluop_i == `RISCV_SUB) ?(exe_src1_i+(~exe_src2_i)+1):
      (exe_aluop_i == `RISCV_LB ) ?(exe_src1_i+ exe_src2_i):
      (exe_aluop_i == `RISCV_LBU ) ?(exe_src1_i+ exe_src2_i):
      (exe_aluop_i == `RISCV_LH ) ?(exe_src1_i+ exe_src2_i):
      (exe_aluop_i == `RISCV_LHU ) ?(exe_src1_i+ exe_src2_i):
      (exe_aluop_i == `RISCV_LW ) ?(exe_src1_i+ exe_src2_i):
      (exe_aluop_i == `RISCV_SB ) ?(exe_src1_i+ exe_src2_i):
      (exe_aluop_i == `RISCV_SW ) ?(exe_src1_i+ exe_src2_i):
      (exe_aluop_i == `RISCV_SH ) ?(exe_src1_i+ exe_src2_i):
      (exe_aluop_i == `RISCV_MUL ) ?(mulres[31:0]):
      (exe_aluop_i == `RISCV_MULH ) ?(mulres[63:32]):
      (exe_aluop_i == `RISCV_MULHSU ) ?(mulressu[63:32]):
      (exe_aluop_i == `RISCV_MULHU ) ?(mulresu[63:32]):
      (exe_aluop_i == `RISCV_DIV ) ?(divres):
      (exe_aluop_i == `RISCV_DIVU ) ?(divres):
      (exe_aluop_i == `RISCV_REM ) ?(exe_src1_i-(exe_src2_i*divres)):
      (exe_aluop_i == `RISCV_REMU ) ?($unsigned(exe_src1_i)-($unsigned(exe_src2_i)*divres)):
      (exe_aluop_i == `RISCV_SLT) ?(($signed(exe_src1_i) < $signed(exe_src2_i))?32'b1: 32'b0):
      (exe_aluop_i == `RISCV_SLTU) ?(($unsigned(exe_src1_i) < $unsigned(exe_src2_i))?32'b1: 32'b0):
      (exe_aluop_i == `RISCV_SLTI) ?(($signed(exe_src1_i) < $signed(exe_src2_i))?32'b1: 32'b0):
      (exe_aluop_i == `RISCV_SLTIU)? ((exe_src1_i < exe_src2_i)? 32'b1 : 32'b0): `ZERO_WORD;



    assign exe_wa_o   = (cpu_rst_n   == `RST_ENABLE ) ? 5'b0 	 : exe_wa_i;
    assign exe_wreg_o = (cpu_rst_n   == `RST_ENABLE ) ? 1'b0 	 : exe_wreg_i;
    
    // ���ݲ�������alutypeȷ��ִ�н׶����յ����������ȿ����Ǵ�д��Ŀ�ļĴ��������ݣ�Ҳ�����Ƿ������ݴ洢���ĵ�ַ��
    assign exe_wd_o = (cpu_rst_n   == `RST_ENABLE ) ? `ZERO_WORD : 
                      (exe_alutype_i == `LOGIC    ) ? logicres : 
                      (exe_alutype_i == `SHIFT    ) ? shiftres  :
                      (exe_alutype_i == `MOVE    ) ? moveres  :
                      (exe_alutype_i == `ARITH    ) ? arithres  :`ZERO_WORD;
                      
    assign stallreq_exe =(cpu_rst_n ==`RST_ENABLE)? `NOSTOP:
                         ((exe_aluop_i==`RISCV_DIV || exe_aluop_i== `RISCV_REM) && (div_ready == `DIV_NOT_READY)) ?`STOP: 
                         ((exe_aluop_i==`RISCV_DIVU || exe_aluop_i== `RISCV_REMU) && (div_ready == `DIV_NOT_READY)) ?`STOP:`NOSTOP;

endmodule