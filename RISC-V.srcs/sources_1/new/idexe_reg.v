`include "defines.v"

module idexe_reg (
    input  wire 				  cpu_clk_50M,
    input  wire 				  cpu_rst_n,
    input wire [`STALL_BUS ]     stall,
    //转移指令
    input wire [`REG_BUS        ]   id_ret_addr,
    output reg [`REG_BUS        ]   exe_ret_addr,

    // 来自译码阶段的信息
    input  wire [`ALUTYPE_BUS  ]  id_alutype,
    input  wire [`ALUOP_BUS    ]  id_aluop,
    input  wire [`REG_BUS      ]  id_src1,
    input  wire [`REG_BUS      ]  id_src2,
    input  wire [`REG_ADDR_BUS ]  id_wa,
    input  wire                   id_wreg,
    input  wire                   id_mreg,
    input  wire [`REG_BUS]        id_din,
    
    // 送至执行阶段的信息
    output reg  [`ALUTYPE_BUS  ]  exe_alutype,
    output reg  [`ALUOP_BUS    ]  exe_aluop,
    output reg  [`REG_BUS      ]  exe_src1,
    output reg  [`REG_BUS      ]  exe_src2,
    output reg  [`REG_ADDR_BUS ]  exe_wa,
    output reg                    exe_wreg,
    output reg                    exe_mreg,
    output reg  [`REG_BUS]        exe_din
    );

    always @(posedge cpu_clk_50M) begin
        // 复位的时候将送至执行阶段的信息清0
        if (cpu_rst_n == `RST_ENABLE) begin
            exe_alutype 	   <= `NOP;
            exe_aluop 		   <= `RISCV_SLL;
            exe_src1 		   <= `ZERO_WORD;
            exe_src2 		   <= `ZERO_WORD;
            exe_wa 			   <= `REG_NOP;
            exe_wreg    		   <= `WRITE_DISABLE;
            exe_mreg           <= `FALSE_V;
            exe_din            <= `ZERO_WORD;     
            exe_ret_addr       <= `ZERO_WORD;      
        end
        else if(stall[2]==`STOP && stall[3]==`NOSTOP) begin
            exe_alutype        <= `NOP;
            exe_aluop          <= `RISCV_SLL;
            exe_src1           <= `ZERO_WORD;
            exe_src2           <= `ZERO_WORD;
            exe_wa             <= `REG_NOP;
            exe_wreg           <= `WRITE_DISABLE;
            exe_mreg           <= `FALSE_V;
            exe_din            <= `ZERO_WORD;
            exe_ret_addr       <= `ZERO_WORD;
        end
        // 将来自译码阶段的信息寄存并送至执行阶段
        else if(stall[2]==`NOSTOP) begin
            exe_alutype 	   <= id_alutype;
            exe_aluop 		   <= id_aluop;
            exe_src1 		   <= id_src1;
            exe_src2 		   <= id_src2;
            exe_wa 			   <= id_wa;
            exe_wreg			   <= id_wreg;
            exe_mreg           <= id_mreg;
            exe_din            <= id_din;  
            exe_ret_addr       <= id_ret_addr;          
        end
    end

endmodule