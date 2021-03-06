`include "defines.v"

module exe_stage (
    input  wire 					cpu_rst_n,

    // 从译码阶段获得的信息
    input  wire [`ALUTYPE_BUS	] 	exe_alutype_i,
    input  wire [`ALUOP_BUS	    ] 	exe_aluop_i,
    input  wire [`REG_BUS 		] 	exe_src1_i,
    input  wire [`REG_BUS 		] 	exe_src2_i,
    input  wire [`REG_ADDR_BUS 	] 	exe_wa_i,
    input  wire 					exe_wreg_i,
    input  wire                    exe_mreg_i,
    input  wire [`REG_BUS      ]   exe_din_i,

    // 送至访存阶段的信息
    output wire [`ALUOP_BUS	    ] 	exe_aluop_o,
    output wire [`REG_ADDR_BUS 	] 	exe_wa_o,
    output wire 					exe_wreg_o,
    output wire [`REG_BUS 		] 	exe_wd_o,
    output wire                     exe_mreg_o,
    output wire [`REG_BUS      ]    exe_din_o,
    
    //转移指令
    input wire [`INST_ADDR_BUS ]    ret_addr,
    
    //暂停
    output wire                     stallreq_exe,
    input wire                      cpu_clk_50M
    );
     
    // 直接传到下一阶段
    assign exe_aluop_o = (cpu_rst_n == `RST_ENABLE) ? 8'b0 : exe_aluop_i;
    assign exe_mreg_o  = (cpu_rst_n == `RST_ENABLE) ? 1'b0: exe_mreg_i;
    assign exe_din_o   = (cpu_rst_n == `RST_ENABLE) ? 32'b0: exe_din_i;
    
    wire [`REG_BUS       ]      logicres;       // 保存逻辑运算的结果
    wire [`REG_BUS       ]      shiftres;       // 保存移位运算结果
    wire [`REG_BUS       ]      moveres;        // 保存移动操作的结果
    wire [`REG_BUS       ]      arithres;       // 保存算术操作的结果
    wire [`REG_BUS       ]      memres;         // 保存访存操作地址
    wire [`DOUBLE_REG_BUS]      mulres;         // 保存乘法操作的结果
    wire [`DOUBLE_REG_BUS]      mulressu;         // 保存乘法操作的结果
    wire [`DOUBLE_REG_BUS]      mulresu;         // 保存乘法操作的结果
    reg  [`DOUBLE_REG_BUS]      divres;         // 保存除法操作的结果
    //除法运算
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

    //记录试商法进行了几轮,当等于16时,表示试商法结束
    reg  [5: 0]          cnt;
    
    reg [65: 0]         dividend;
    reg [1: 0]          state;
    reg [33:0]          divisor;
    reg [31:0]          temp_op1;
    reg [31: 0]         temp_op2;
    
    wire [33: 0]        divisor_temp;
    wire [33: 0]        divisor2;
    wire [33: 0]        divisor3;

    //dividend的低32位保存的是被除数、中间结果,第k次迭代结束的时候, dividend[k:]保存的就是当前得到的中间结
    //果 dividend32k+1]保存的就是被除数中还没有参与运算的数据, dividend高32位是每次代时的被减数
    assign divisor2=divisor+divisor;
    assign divisor3=divisor2+divisor;
    assign div_temp0 ={1'b000,dividend[63:32]}-{1'b000,`ZERO_WORD};//部分余数与被除数的0倍相减
    assign div_temp1={1'b000,dividend[63:32]}-{1'b0,divisor};   //部分余数与被除数的1倍相减
    assign div_temp2={1'b000,dividend[63:32]}-{1'b0,divisor2};  //部分余数与被除数的2倍相减
    assign div_temp3={1'b000,dividend[63:32]}-{1'b0,divisor3};  //部分余数与被除数的3倍相减

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
    //分3种情况:
    //(1)开始除法运算,如果除数为0那么进 DivBy Zero状态
    //(2)开始除法运算,且除数不为0,那么进入Divn状态,初始化cnt为0如果是有符号
    //除法,且被除数或者除数为负,那么对被除数或者除数求正数的补码。除数保存到
    //divisordividend中,将被除数的最高位保存到的第32位,准备进行第一次迭代
    //(3)没有进行除法运算,保持*
    `DIV_FREE:begin
        if(div_start == `DIV_START) begin
            if(div_opdata2 == `ZERO_WORD) begin //除数为0
                state <= `DIV_BY_ZERO;
            end else begin                      //除数不为0
                state <= `DIV_ON;
                cnt <= 6'b000000;
                if(div_opdata1[31] == 1'b1 && signed_div_i) begin
                    temp_op1=~div_opdata1+1;    //取正数的补码
                end else begin
                    temp_op1 =div_opdata1;
                end
                if(div_opdata2[31]==1'b1 && signed_div_i) begin
                    temp_op2 =~div_opdata2+1;   //取正数的补码
                end else begin
                    temp_op2 =div_opdata2;
                end
                dividend <= {`ZERO_WORD, `ZERO_WORD};
                dividend[31:0] <=temp_op1;
                divisor  <= temp_op2;
            end
    end else begin                      //没有开始除法运算
        div_ready <= `DIV_NOT_READY;
        divres    <= {`ZERO_WORD,`ZERO_WORD};
    end 
    end
            //如果进入DivByZero状态.那么直接进入 DivEnd状态除法结束.结果为0
    `DIV_BY_ZERO: begin          //DivByZero
             dividend <= {`ZERO_WORD, `ZERO_WORD};
             state    <= `DIV_END;
     end

    //(1)如果cnt不为16那么表示试商法还没有结束,此时如果减法结果 div temp为负那么此
    //   次选代结果是0:如果减法结果div_temp为正,那么此次选代结果是1 dividend的最低位
    //(2)如果cnt为16,那么表示试商法结束,如果是有符号除法,且被除数、除数一正一负,那
    //   么将试商法的结果求正数的补码,得到最终的结果,此处的商、余数都要求正数的补
    //   码商保存在dividend的低32位,余数保存在dividen dDivEnd的高32位.同时进入状态
    `DIV_ON: begin   //DivOn
            if(cnt!=6'b100010) begin //cnt不为16,示试商法还没有结束
                if(div_temp[34]==1'b1)begin
                //如果 divtemp[34]为1,(minuend-n-n)结果小ddd移位,这样就将被除数还
                //没有参与运算的最高位加入到下一次选代的被减数中,同时将0追加到中间结果
                    dividend <={dividend[63:0], 2'b00};
                end else begin
                //如果di_temp[34]为0,表示(minuend--n)结果大于等于0,将减法的结果与被除数还没有参运算
                //的最高位加入到下一次选代的被减数中,同时将1追加到中间结果
                    dividend <={div_temp[31:0], dividend[31:0], mul_cnt};
                end
                cnt <= cnt+2;
             end else begin  //试商法结束
                if((div_opdata1[31]^div_opdata2[31])==1'b1 && signed_div_i) begin
                    dividend[31:0] <= (~dividend[31:0]+1); //取正数的补码
                end
                if((div_opdata1[31]^dividend[65])== 1'b1  && signed_div_i) begin
                    dividend[65: 34] <=(~dividend[65: 34]+1);//取正数的补码
                end
                state <= `DIV_END; //进入 DivEnd状态
                cnt   <= 6'b000000; //cnt清零
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
    
    // 根据内部操作码aluop进行逻辑运算
    assign logicres=(cpu_rst_n ==`RST_ENABLE)? `ZERO_WORD:
    (exe_aluop_i == `RISCV_AND)? (exe_src1_i & exe_src2_i):
    (exe_aluop_i == `RISCV_OR)? (exe_src1_i | exe_src2_i):
    (exe_aluop_i == `RISCV_ORI)? (exe_src1_i | exe_src2_i):
    (exe_aluop_i == `RISCV_ANDI)? (exe_src1_i & exe_src2_i):
    (exe_aluop_i == `RISCV_XORI)? (exe_src1_i ^ exe_src2_i):
    (exe_aluop_i == `RISCV_XOR)? (exe_src1_i ^ exe_src2_i):
    (exe_aluop_i == `RISCV_LUI)? exe_src2_i : `ZERO_WORD;
    
    //根据内部操作码aluop进行移位运算
    assign shiftres=(cpu_rst_n == `RST_ENABLE)? `ZERO_WORD:
    (exe_aluop_i == `RISCV_SLL)? (exe_src2_i << exe_src1_i[4:0]) :
    (exe_aluop_i == `RISCV_SRL)? (exe_src2_i >> exe_src1_i[4:0]) :
    (exe_aluop_i == `RISCV_SRA)? ( {32{exe_src2_i[31]}} << ( 6'd32 - {1'b0, exe_src1_i[4:0]} ) ) | ( exe_src2_i >> exe_src1_i[4:0] ) :
    (exe_aluop_i == `RISCV_SRLI)? (exe_src2_i >> exe_src1_i) :
    (exe_aluop_i == `RISCV_SRAI)? ( {32{exe_src2_i[31]}} << ( 6'd32 - {1'b0, exe_src1_i[4:0]} ) ) | ( exe_src2_i >> exe_src1_i[4:0] ) :
    (exe_aluop_i == `RISCV_SLLI)? (exe_src2_i << exe_src1_i) : `ZERO_WORD;

    //根据内部操作码aluop进行数据移动
     assign moveres =(cpu_rst_n ==`RST_ENABLE)? `ZERO_WORD: `ZERO_WORD;
     
      //根据内部 aluop操作码进行乘法运算
     assign mulres=($signed(exe_src1_i)* $signed(exe_src2_i));
     assign mulressu={{32{exe_src1_i[31]}},exe_src1_i}* {{32{1'b0}},exe_src2_i};
     assign mulresu={{32{1'b0}},exe_src1_i}* {{32{1'b0}},exe_src2_i};
     

     //根据内部操作码 aluop进行算术运算
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
    
    // 根据操作类型alutype确定执行阶段最终的运算结果（既可能是待写入目的寄存器的数据，也可能是访问数据存储器的地址）
    assign exe_wd_o = (cpu_rst_n   == `RST_ENABLE ) ? `ZERO_WORD : 
                      (exe_alutype_i == `LOGIC    ) ? logicres : 
                      (exe_alutype_i == `SHIFT    ) ? shiftres  :
                      (exe_alutype_i == `MOVE    ) ? moveres  :
                      (exe_alutype_i == `ARITH    ) ? arithres  :`ZERO_WORD;
                      
    assign stallreq_exe =(cpu_rst_n ==`RST_ENABLE)? `NOSTOP:
                         ((exe_aluop_i==`RISCV_DIV || exe_aluop_i== `RISCV_REM) && (div_ready == `DIV_NOT_READY)) ?`STOP: 
                         ((exe_aluop_i==`RISCV_DIVU || exe_aluop_i== `RISCV_REMU) && (div_ready == `DIV_NOT_READY)) ?`STOP:`NOSTOP;

endmodule