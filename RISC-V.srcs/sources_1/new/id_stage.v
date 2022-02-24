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
      
    // 送至执行阶段的译码信息
    output wire [`ALUTYPE_BUS  ]    id_alutype_o,
    output wire [`ALUOP_BUS    ]    id_aluop_o,
    output wire [`REG_ADDR_BUS ]    id_wa_o,
    output wire                     id_wreg_o,

    // 送至执行阶段的源操作数1、源操作数2
    output wire [`REG_BUS      ]    id_src1_o,
    output wire [`REG_BUS      ]    id_src2_o,
    output wire                     id_mreg_o,
    output wire [`REG_BUS]          id_din_o,
      
    // 送至读通用寄存器堆端口的使能和地址
    output wire                     rreg1,
    output wire [`REG_ADDR_BUS ]    ra1, 
    output wire                     rreg2,
    output wire [`REG_ADDR_BUS ]    ra2,
    
    /*-------------------- 定向前推 --------------------*/
    //从执行阶段获得的写回信号
    input wire                      exe2id_wreg,
    input wire [`REG_ADDR_BUS]      exe2id_wa,
    input wire [`INST_BUS]          exe2id_wd,
    //从访存阶段获得的写回信号
    input wire                      mem2id_wreg,
    input wire [`REG_ADDR_BUS]      mem2id_wa,
    input wire [`INST_BUS]          mem2id_wd,
    
    /*-------------------- 跳转指令 --------------------*/
    input wire [`INST_ADDR_BUS]     pc_plus_4,

    output wire [`INST_ADDR_BUS]    jump_addr_1,
    output wire [`INST_ADDR_BUS]    jump_addr_2,
    output wire [`INST_ADDR_BUS]    jump_addr_3,
    output wire [`JTSEL_BUS    ]    jtsel,
    output wire [`INST_ADDR_BUS]    ret_addr,
    
    //从执行阶段和访存阶段回传的存储器到寄存器使能信号
    input wire                      exe2id_mreg,
    input wire                      mem2id_mreg,

    //暂停请求信号
    output wire                     stallreq_id
    );
    
    // 根据小端模式组织指令字
    wire [`INST_BUS] id_inst = {id_inst_i[7:0], id_inst_i[15:8], id_inst_i[23:16], id_inst_i[31:24]};

    // 提取指令字中各个字段的信息
    wire [6 :0] op   = id_inst[6 : 0];
    wire [6 :0] func7 = id_inst[31:25];
    wire [2:0]  func3 = id_inst[14:12];
    wire [4 :0] rd   = id_inst[11: 7];
    wire [4 :0] rs1   = id_inst[19:15];
    wire [4 :0] rs2   = id_inst[24:20];
    wire [19:0] imm1 = id_inst[31: 12]; //U型指令立即数
    wire [11:0] imm2 = id_inst[31:20];  //I型指令立即数
    wire [11: 0] imm3 = {id_inst[31:25],id_inst[11:7]};  //S型指令立即数
    
    wire [5:0] sa = id_inst[25: 20];

    /*-------------------- 第一级译码逻辑：确定当前需要译码的指令 --------------------*/
    wire inst_reg  = ~op[6] &op[5] &op[4] &~op[3] &~op[2] &op[1] &op[0] ;
    //R型
    wire inst_and  = inst_reg& ~func7[6]& ~func7[5]& ~func7[4]&~func7[3]& ~func7[2]&~func7[1]&~func7[0]& func3[2] &func3[1] &func3[0] ;
    wire inst_add  = inst_reg& ~func7[6]& ~func7[5]& ~func7[4]&~func7[3]& ~func7[2]&~func7[1]&~func7[0]& ~func3[2] &~func3[1] &~func3[0] ;
    wire inst_slt  = inst_reg& ~func7[6]& ~func7[5]& ~func7[4]&~func7[3]& ~func7[2]&~func7[1]&~func7[0]& ~func3[2] &func3[1] &~func3[0] ;
    wire inst_sll  = inst_reg& ~func7[6]& ~func7[5]& ~func7[4]&~func7[3]& ~func7[2]&~func7[1]&~func7[0]& ~func3[2] &~func3[1] &func3[0] ;
    wire inst_sub  = inst_reg& ~func7[6]& func7[5]& ~func7[4]&~func7[3]& ~func7[2]&~func7[1]&~func7[0]& ~func3[2] &~func3[1] &~func3[0] ;
    wire inst_sltu  = inst_reg& ~func7[6]& ~func7[5]& ~func7[4]&~func7[3]& ~func7[2]&~func7[1]&~func7[0]& ~func3[2] &func3[1] &func3[0] ;
    wire inst_or  = inst_reg& ~func7[6]& ~func7[5]& ~func7[4]&~func7[3]& ~func7[2]&~func7[1]&~func7[0]& func3[2] &func3[1] &~func3[0] ;
    wire inst_xor  = inst_reg& ~func7[6]& ~func7[5]& ~func7[4]&~func7[3]& ~func7[2]&~func7[1]&~func7[0]& func3[2] &~func3[1] &~func3[0] ;
    wire inst_srl  = inst_reg& ~func7[6]& ~func7[5]& ~func7[4]&~func7[3]& ~func7[2]&~func7[1]&~func7[0]& func3[2] &~func3[1] &func3[0] ;
    wire inst_sra  = inst_reg& ~func7[6]& func7[5]& ~func7[4]&~func7[3]& ~func7[2]&~func7[1]&~func7[0]& func3[2] &~func3[1] &func3[0] ;
    //U型
    wire inst_lui  = ~op[6]& op[5]& op[4]&~op[3]& op[2]&op[1]&op[0] ;  
    //I型
    wire inst_ori  = ~op[6]& ~op[5]& op[4]&~op[3]& ~op[2]&op[1]&op[0]& func3[2] &func3[1] &~func3[0] ;
    wire inst_addi  = ~op[6]& ~op[5]& op[4]&~op[3]& ~op[2]&op[1]&op[0]& ~func3[2] &~func3[1] &~func3[0] ;
    wire inst_slti  = ~op[6]& ~op[5]& op[4]&~op[3]& ~op[2]&op[1]&op[0]&~func3[2] &func3[1] &~func3[0] ;
    wire inst_sltiu =  ~op[6]& ~op[5]& op[4]&~op[3]& ~op[2]&op[1]&op[0]&~func3[2] &func3[1] & func3[0] ;
    wire inst_andi  = ~op[6]& ~op[5]& op[4]&~op[3]& ~op[2]&op[1]&op[0]& func3[2] &func3[1] &func3[0] ;
    wire inst_xori  = ~op[6]& ~op[5]& op[4]&~op[3]& ~op[2]&op[1]&op[0]& func3[2] &~func3[1] &~func3[0] ;
    wire inst_lb  = ~op[6]& ~op[5]& ~op[4]&~op[3]& ~op[2]&op[1]&op[0]& ~func3[2] &~func3[1] &~func3[0] ;
    wire inst_lw  = ~op[6]& ~op[5]& ~op[4]&~op[3]& ~op[2]&op[1]&op[0]& ~func3[2] &func3[1] &~func3[0] ;
    wire inst_lbu  = ~op[6]& ~op[5]& ~op[4]&~op[3]& ~op[2]&op[1]&op[0]& func3[2] &~func3[1] &~func3[0] ;
    wire inst_lh  = ~op[6]& ~op[5]& ~op[4]&~op[3]& ~op[2]&op[1]&op[0]& ~func3[2] &~func3[1] &func3[0] ;
    wire inst_lhu  = ~op[6]& ~op[5]& ~op[4]&~op[3]& ~op[2]&op[1]&op[0]& func3[2] &~func3[1] &func3[0] ;
    wire inst_slli =~op[6]& ~op[5]& op[4]&~op[3]& ~op[2]&op[1]&op[0]& ~func7[6]& ~func7[5]& ~func7[4]&~func7[3]& ~func7[2]&~func7[1]&~func7[0]& ~func3[2] &~func3[1] &func3[0]  ;
    wire inst_srli =~op[6]& ~op[5]& op[4]&~op[3]& ~op[2]&op[1]&op[0]& ~func7[6]& ~func7[5]& ~func7[4]&~func7[3]& ~func7[2]&~func7[1]&~func7[0]& func3[2] &~func3[1] &func3[0]  ;
    wire inst_srai =~op[6]& ~op[5]& op[4]&~op[3]& ~op[2]&op[1]&op[0]& ~func7[6]& func7[5]& ~func7[4]&~func7[3]& ~func7[2]&~func7[1]&~func7[0]& func3[2] &~func3[1] &func3[0]  ;
    wire inst_jalr = op[6]& op[5]& ~op[4]&~op[3]& op[2]&op[1]&op[0]& ~func3[2] &~func3[1] & ~func3[0] ;
    //S型
    wire inst_sb  = ~op[6]& op[5]& ~op[4]&~op[3]& ~op[2]&op[1]&op[0]& ~func3[2] &~func3[1] &~func3[0] ;
    wire inst_sw  = ~op[6]& op[5]& ~op[4]&~op[3]& ~op[2]&op[1]&op[0]& ~func3[2] &func3[1] &~func3[0] ;
    wire inst_sh  = ~op[6]& op[5]& ~op[4]&~op[3]& ~op[2]&op[1]&op[0]& ~func3[2] &~func3[1] &func3[0] ;
    
    //B型
    wire inst_beq = op[6]& op[5]& ~op[4]&~op[3]& ~op[2]&op[1]& op[0]& ~func3[2] &~func3[1] &~func3[0] ;
    wire inst_bne = op[6]& op[5]& ~op[4]&~op[3]& ~op[2]&op[1]& op[0]& ~func3[2] &~func3[1] & func3[0] ;
    
    //J型
    wire inst_jal = op[6]& op[5]& ~op[4]&op[3]& op[2]&op[1]& op[0];
    /*------------------------------------------------------------------------------*/

    /*-------------------- 第二级译码逻辑：生成具体控制信号 --------------------*/
    // 操作类型alutype
    assign id_alutype_o[2] =(cpu_rst_n == `RST_ENABLE)? 1'b0: (inst_sll | inst_slli | inst_srli | inst_srai | inst_srl | inst_sra | inst_bne);
    assign id_alutype_o[1] =(cpu_rst_n == `RST_ENABLE)?1'b0:(inst_and |  inst_ori | inst_lui | inst_andi | inst_xori | inst_xor | inst_or);
    assign id_alutype_o[0] =(cpu_rst_n ==`RST_ENABLE)?1'b0: 
        (inst_add | inst_slt |inst_addi | inst_slti | inst_sltiu | inst_lb |inst_lw | inst_sb | inst_sw | inst_sh | inst_lh | inst_lbu |inst_lhu | inst_sub | inst_sltu | inst_bne);

    // 内部操作码aluop
    assign id_aluop_o[7] =(cpu_rst_n ==`RST_ENABLE)? 1'b0: 1'b0;
    assign id_aluop_o[6]=(cpu_rst_n ==`RST_ENABLE)? 1'b0: 1'b0;
    assign id_aluop_o[5] =(cpu_rst_n ==`RST_ENABLE)? 1'b0: (inst_sltu | inst_xor | inst_srl |inst_sra | inst_or | inst_and);
    assign id_aluop_o[4] =(cpu_rst_n ==`RST_ENABLE)? 1'b0:
     (inst_add   |  inst_sll | inst_xori | inst_addi | inst_slti | inst_sltiu | inst_sh | inst_slli | inst_srli | inst_srai| inst_sub | inst_slt |
     inst_ori  | inst_sb | inst_sw | inst_andi);
    assign id_aluop_o[3]=(cpu_rst_n==`RST_ENABLE)?1'b0:
     (inst_add   | inst_lw | inst_lb | inst_lh | inst_lbu | inst_lhu | inst_slli | inst_srli | inst_srai | inst_sub | inst_sll | inst_slt |
        inst_andi);
    assign id_aluop_o[2]=(cpu_rst_n==`RST_ENABLE)?1'b0:
     (inst_slt | inst_and |   inst_xori | inst_sltiu | inst_lw | inst_lh | inst_lbu | inst_lhu | inst_add | inst_sub | inst_sll | inst_or | inst_bne |
     inst_ori |  inst_slti);
     assign id_aluop_o[1] =(cpu_rst_n ==`RST_ENABLE)? 1'b0:
     ( inst_slt   | inst_sw | inst_ori | inst_xori | inst_addi | inst_lb | inst_lbu | inst_lhu | inst_srli |inst_srai | inst_sll | inst_srl | inst_sra | inst_bne);
     assign id_aluop_o[0] =(cpu_rst_n ==`RST_ENABLE)?1'b0:
     ( inst_lui | inst_sltiu | inst_lw | inst_sh | inst_lhu | inst_slli | inst_srai | inst_sub | inst_slt | inst_xor | inst_sra |
    inst_ori | inst_addi | inst_lb | inst_and);

    // 写通用寄存器使能信号
    assign id_wreg_o=(cpu_rst_n == `RST_ENABLE)?1'b0:
        (inst_add | inst_sub |  inst_slt | inst_and | inst_sll | inst_lui | inst_xori | inst_lh | inst_lbu | inst_lhu | inst_slli | inst_srli | inst_srai | inst_sll | inst_slt | inst_sltu |
        inst_ori |  inst_addi | inst_slti | inst_sltiu | inst_lb | inst_lw | inst_andi | inst_xor | inst_srl | inst_sra | inst_or );
    //移位使能指令
    wire shift = inst_slli | inst_srli | inst_srai ;
    //生成相等使能信号
    wire equ =(cpu_rst_n == `RST_ENABLE)?1'b0:
                   (inst_beq)?(id_src1_o == id_src2_o):
                   (inst_bne)?(id_src1_o != id_src2_o):1'b0;
    //加载高半字使能信号
    wire upper =inst_lui;
    //立即数使能信号
    wire immsel = inst_ori  | inst_lui | inst_addi | inst_andi | inst_slti | inst_sltiu | inst_lb | inst_lh | inst_lw | inst_xori |inst_sb | inst_sw | inst_sh | inst_lbu | inst_lhu;
    
    //目的寄存器选择信号
    wire rtsel=0;
    //符号扩展使能信号
    wire sext =inst_addi | inst_andi | inst_ori | inst_slti | inst_lb | inst_xori | inst_lw | inst_sb | inst_sw | inst_sh | inst_lh;
    //存储器到寄存器使能信号
    assign id_mreg_o =(cpu_rst_n == `RST_ENABLE)? 1'b0: (inst_lb | inst_lw | inst_lh | inst_lbu | inst_lhu );
    //读通用寄存器堆端口1使能信号
    assign rreg1=(cpu_rst_n == `RST_ENABLE)?1'b0:
        (inst_add | inst_slt | inst_and |  inst_andi | inst_xori | inst_sh | inst_slli | inst_srli | inst_srai | inst_sub | inst_sll | inst_slt | inst_sltu | inst_xor | inst_or |
        inst_ori | inst_addi | inst_slti | inst_sltiu | inst_lb | inst_lw | inst_sb | inst_sw | inst_lh | inst_lbu | inst_lhu  | inst_srl | inst_sra | inst_bne);
    //读通用寄存器堆读端口2使能信号
    assign rreg2=(cpu_rst_n==`RST_ENABLE)?1'b0:
         (inst_add | inst_sub |  inst_slt | inst_and |  inst_sll | inst_sb | inst_sw | inst_sh | inst_sll | inst_slt | inst_sltu | inst_xor | inst_srl | inst_sra | inst_or | inst_bne);
    //生成子程序调用信号
    wire jal=inst_jal;
     
    //生成转移地址选择信号
    assign jtsel[1]= inst_beq & equ | inst_bne & equ;
    assign jtsel[0]= inst_jal | inst_beq & equ | inst_bne & equ;
     
    //产生源操作数选择信号
     wire [1:0] fwrd1 = (cpu_rst_n==`RST_ENABLE)? 2'b00:
                             (exe2id_wreg == `WRITE_ENABLE && exe2id_wa == ra1 && rreg1 ==`READ_ENABLE)?2'b01:
                             (mem2id_wreg == `WRITE_ENABLE && mem2id_wa == ra1 && rreg1 ==`READ_ENABLE)?2'b10:
                             (rreg1 ==`READ_ENABLE)?2'b11:2'b00;
     
      wire [1:0] fwrd2 = (cpu_rst_n==`RST_ENABLE)? 2'b00:
                             (exe2id_wreg == `WRITE_ENABLE && exe2id_wa == ra2 && rreg2 ==`READ_ENABLE)?2'b01:
                             (mem2id_wreg == `WRITE_ENABLE && mem2id_wa == ra2 && rreg2 ==`READ_ENABLE)?2'b10:
                             (rreg2 ==`READ_ENABLE)?2'b11:2'b00;
    /*------------------------------------------------------------------------------*/

    // 读通用寄存器堆端口1的地址为rs1字段，读端口2的地址为rs2字段
    assign ra1   = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : rs1;
    assign ra2   = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : rs2;
                                            
    //获得指令操作所需的立即数
    wire S_type=inst_sw |inst_sh | inst_sb;
    wire [11:0] imm4;
    assign imm4=(S_type==`TRUE_V)? {id_inst[31:25],id_inst[11:7]}:id_inst[31:20];
    wire [31: 0] imm_ext=(cpu_rst_n ==`RST_ENABLE)? `ZERO_WORD:
    (upper == `UPPER_ENABLE )?(imm1<<12):
    (sext ==`SIGNED_EXT)?{{20{imm4[11]}},imm4}:{{20{1'b0}},imm4};
    //获得待写入目的寄存器的地址(rs1或rd)
    assign id_wa_o =(cpu_rst_n ==`RST_ENABLE)? `ZERO_WORD :(rtsel ==`RT_ENABLE )? rs1:rd;
    //获得访存阶段要存入数据存储器的数据(来自通用寄存器堆读数据端口2)
    assign id_din_o =(cpu_rst_n ==`RST_ENABLE)? `ZERO_WORD: rd2;
    //获得源操作数1。如果 shift信号有效,则源操作数1为移位位数,否则为从读通用寄存器堆端口1获得的数据
    assign id_src1_o =(cpu_rst_n == `RST_ENABLE)? `ZERO_WORD:
    (shift ==`SHIFT_ENABLE )?{26'b0, sa}:
    (fwrd1 ==2'b01 )? exe2id_wd:
    (fwrd1 ==2'b10 )? mem2id_wd:
     (fwrd1 ==2'b11 )? rd1: `ZERO_WORD;
    //获得源操作数2。如果 immsel信号有效,则源操作数1为立即数,否则为从读通用寄存器堆端口2获得的数据
    assign id_src2_o =(cpu_rst_n == `RST_ENABLE)? `ZERO_WORD:
    (shift ==`SHIFT_ENABLE )?rd1:
    (immsel ==`IMM_ENABLE )?imm_ext:
    (fwrd2 ==2'b01 )? exe2id_wd:
    (fwrd2 ==2'b10 )? mem2id_wd:
     (fwrd2 ==2'b11 )? rd2: `ZERO_WORD;
    
    //生成计算转移地址所需信号
    wire [`INST_ADDR_BUS] pc_plus_8=pc_plus_4+4;
    wire [`JUMP_BUS     ] instr_index =id_inst[25:0];
    wire [`INST_ADDR_BUS] imm_jump={{14{imm1[15]}},imm1,2'b00};

    //获得转移地址
    assign jump_addr_1 ={pc_plus_4[31:28],instr_index,2'b00};
    assign jump_addr_2 =pc_plus_4+imm_jump;
    assign jump_addr_3 =id_src1_o;

    //生成子程序调用的返回地址
    assign ret_addr =pc_plus_8;
    
    assign stallreq_id = (cpu_rst_n==`RST_ENABLE)? `NOSTOP:
                         (((exe2id_wreg == `WRITE_ENABLE && exe2id_wa == ra1 && rreg1 == `READ_ENABLE)||
                         (exe2id_wreg == `WRITE_ENABLE && exe2id_wa == ra2 && rreg2 == `READ_ENABLE))&&
                         (exe2id_mreg == 1'b1))?`STOP:
                         (((mem2id_wreg == `WRITE_ENABLE && mem2id_wa == ra1 && rreg1 == `READ_ENABLE)||
                         (mem2id_wreg == `WRITE_ENABLE && mem2id_wa == ra2 && rreg2 == `READ_ENABLE))&&
                         (mem2id_mreg == 1'b1))?`STOP:`NOSTOP;  

endmodule
