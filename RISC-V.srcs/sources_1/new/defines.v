`timescale 1ns / 1ps


/*------------------- ȫ�ֲ��� -------------------*/
`define RST_ENABLE      1'b0                // ��λ�ź���Ч  RST_ENABLE
`define RST_DISABLE     1'b1                // ��λ�ź���Ч
`define ZERO_WORD       32'h00000000        // 32λ����ֵ0
`define ZERO_DWORD      64'b0               // 64λ����ֵ0
`define WRITE_ENABLE    1'b1                // ʹ��д
`define WRITE_DISABLE   1'b0                // ��ֹд
`define READ_ENABLE     1'b1                // ʹ�ܶ�
`define READ_DISABLE    1'b0                // ��ֹ��
`define ALUOP_BUS       7 : 0               // ����׶ε����aluop_o�Ŀ��
`define SHIFT_ENABLE    1'b1                // ��λָ��ʹ�� 
`define ALUTYPE_BUS     2 : 0               // ����׶ε����alutype_o�Ŀ��  
`define TRUE_V          1'b1                // �߼�"��"  
`define FALSE_V         1'b0                // �߼�"��"  
`define CHIP_ENABLE     1'b1                // оƬʹ��  
`define CHIP_DISABLE    1'b0                // оƬ��ֹ  
`define WORD_BUS        31: 0               // 32λ��
`define DOUBLE_REG_BUS  63: 0               // ������ͨ�üĴ����������߿��
`define RT_ENABLE       1'b1                // rtѡ��ʹ��
`define SIGNED_EXT      1'b1                // ������չʹ��
`define IMM_ENABLE      1'b1                // ������ѡ��ʹ��
`define UPPER_ENABLE    1'b1                // ��������λʹ��
`define MREG_ENABLE     1'b1                // д�ؽ׶δ洢�����ѡ���ź�
`define BSEL_BUS        3 : 0               // ���ݴ洢���ֽ�ѡ���źſ��
`define PC_INIT         32'h00000000        // PC��ʼֵ

/*------------------- ָ���ֲ��� -------------------*/
`define INST_ADDR_BUS   31: 0               // ָ��ĵ�ַ���
`define INST_BUS        31: 0               // ָ������ݿ��

// ��������alutype
`define NOP             3'b000
`define ARITH           3'b001
`define LOGIC           3'b010
`define MOVE            3'b011
`define SHIFT           3'b100

// ������aluop
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

/*------------------- ͨ�üĴ����Ѳ��� -------------------*/
`define REG_BUS         31: 0               // �Ĵ������ݿ��
`define REG_ADDR_BUS    4 : 0               // �Ĵ����ĵ�ַ���
`define REG_NUM         32                  // �Ĵ�������32��
`define REG_NOP         5'b00000            // ��żĴ���

