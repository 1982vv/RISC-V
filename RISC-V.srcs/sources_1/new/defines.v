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
`define RISCV_SLL             8'h1E
`define RISCV_ADD             8'h1C
`define RISCV_ADDI            8'h13
`define RISCV_SLTI            8'h14
`define RISCV_SLTIU           8'h15
`define RISCV_XORI            8'h16
`define RISCV_ANDI            8'h17
`define RISCV_SLLI            8'h18
`define RISCV_SRLI            8'h19
`define RISCV_SRAI            8'h1A
`define RISCV_SUB             8'h1D
`define RISCV_SLTU            8'h20
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

/*------------------- 通用寄存器堆参数 -------------------*/
`define REG_BUS         31: 0               // 寄存器数据宽度
`define REG_ADDR_BUS    4 : 0               // 寄存器的地址宽度
`define REG_NUM         32                  // 寄存器数量32个
`define REG_NOP         5'b00000            // 零号寄存器

