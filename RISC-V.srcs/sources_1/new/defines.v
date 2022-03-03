`timescale 1ns / 1ps


/*------------------- 全局参数 -------------------*/
`define RST_ENABLE      1'b0                // 复位信号有效  RST_ENABLE
`define RST_DISABLE     1'b1                // 复位信号无效
`define ZERO_WORD       32'h00000000        // 32位的数值0
`define ZERO_DWORD      64'b0               // 64位的数值0
`define WRITE_ENABLE    1'b1                // 使能写
`define WRITE_DISABLE   1'b0                // 禁止写
`define READ_ENABLE     1'b1                // 使能读
`define READ_DISABLE    1'b0                // 禁止读
`define ALUOP_BUS       7 : 0               // 译码阶段的输出aluop_o的宽度
`define SHIFT_ENABLE    1'b1                // 移位指令使能 
`define ALUTYPE_BUS     2 : 0               // 译码阶段的输出alutype_o的宽度  
`define TRUE_V          1'b1                // 逻辑"真"  
`define FALSE_V         1'b0                // 逻辑"假"  
`define CHIP_ENABLE     1'b1                // 芯片使能  
`define CHIP_DISABLE    1'b0                // 芯片禁止  
`define WORD_BUS        31: 0               // 32位宽
`define DOUBLE_REG_BUS  63: 0               // 两倍的通用寄存器的数据线宽度
`define RT_ENABLE       1'b1                // rt选择使能
`define SIGNED_EXT      1'b1                // 符号扩展使能
`define IMM_ENABLE      1'b1                // 立即数选择使能
`define UPPER_ENABLE    1'b1                // 立即数移位使能
`define MREG_ENABLE     1'b1                // 写回阶段存储器结果选择信号
`define BSEL_BUS        3 : 0               // 数据存储器字节选择信号宽度
`define PC_INIT         32'h00000000        // PC初始值
`define JUMP_BUS        25:0                //J型指令字中instr_index字段的长度
`define JTSEL_BUS       1:0                 //转移地址选择信号的宽度

/*------------------- 指令字参数 -------------------*/
`define INST_ADDR_BUS   31: 0               // 指令的地址宽度
`define INST_BUS        31: 0               // 指令的数据宽度

// 操作类型alutype
`define NOP             3'b000
`define ARITH           3'b001
`define LOGIC           3'b010
`define MOVE            3'b011
`define SHIFT           3'b100

// 操作码aluop
`define RISCV_LUI             8'h01
`define RISCV_JAL             8'h03
`define RISCV_SLL             8'h1E
`define RISCV_ADD             8'h1C
`define RISCV_ADDI            8'h13
`define RISCV_SLTI            8'h14
`define RISCV_SLTIU           8'h15
`define RISCV_XORI            8'h16
`define RISCV_ANDI            8'h18
`define RISCV_SLLI            8'h19
`define RISCV_SRLI            8'h1A
`define RISCV_SRAI            8'h1B
`define RISCV_SUB             8'h1D
`define RISCV_SLTU            8'h20
`define RISCV_XOR             8'h21
`define RISCV_SRL             8'h22
`define RISCV_SRA             8'h23
`define RISCV_OR              8'h24
`define RISCV_AND             8'h25
`define RISCV_ORI             8'h17
`define RISCV_SLT             8'h1F
`define RISCV_LB              8'h0B
`define RISCV_LBU             8'h0E
`define RISCV_LH              8'h0C
`define RISCV_LHU             8'h0F
`define RISCV_LW              8'h0D
`define RISCV_SB              8'h10
`define RISCV_SH              8'h11
`define RISCV_SW              8'h12
`define RISCV_BNE             8'h06
`define RISCV_MUL             8'h30
`define RISCV_MULH            8'h31
`define RISCV_MULHSU          8'h32
`define RISCV_MULHU           8'h33
`define RISCV_DIV             8'h34
`define RISCV_DIVU            8'h35
`define RISCV_REM             8'h36
`define RISCV_REMU            8'h37

/*------------------- 通用寄存器堆参数 -------------------*/
`define REG_BUS         31: 0               // 寄存器数据宽度
`define REG_ADDR_BUS    4 : 0               // 寄存器的地址宽度
`define REG_NUM         32                  // 寄存器数量32个
`define REG_NOP         5'b00000            // 零号寄存器

/*------------------- 流水线暂停 -------------------*/
`define STALL_BUS       3 : 0               // 暂停信号宽度
`define STOP            1'b1                // 流水线暂停
`define NOSTOP          1'b0                // 流水线不暂停

/*------------------- 除法指令参数 -------------------*/
`define DIV_FREE            2'b00           // 除法准备状态
`define DIV_BY_ZERO         2'b01           // 判断是否除零状态
`define DIV_ON              2'b10           // 除法开始状态
`define DIV_END             2'b11           // 除法结束状态
`define DIV_READY           1'b1            // 除法运算结束信号
`define DIV_NOT_READY       1'b0            // 除法运算未结束信号
`define DIV_START           1'b1            // 除法开始信号
`define DIV_STOP            1'b0            // 除法未开始信号


/************************SoC添加 begin*******************************/
`define IO_ADDR_BASE        16'hbfd0        // 外部IO设备基址
/************************SoC添加 end*********************************/
