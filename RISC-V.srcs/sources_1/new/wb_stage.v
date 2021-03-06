`include "defines.v"

module wb_stage(
    input  wire                   cpu_rst_n,
    // 从访存阶段获得的信息
	input  wire [`REG_ADDR_BUS  ] wb_wa_i,
	input  wire                   wb_wreg_i,
	input  wire [`REG_BUS       ] wb_dreg_i,
	input  wire                   wb_mreg_i,
    input  wire [`BSEL_BUS      ] wb_dre_i,
    input  wire                   wb_unsign_i,
    
	//从数据存储器读出的数据
    input  wire [`WORD_BUS      ] dm,

    // 写回目的寄存器的数据
    output wire [`REG_ADDR_BUS  ] wb_wa_o,
	output wire                   wb_wreg_o,
    output wire [`WORD_BUS      ] wb_wd_o
    );

    assign wb_wa_o      = (cpu_rst_n == `RST_ENABLE) ? 5'b0 : wb_wa_i;
    assign wb_wreg_o    = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : wb_wreg_i;
    //根据读字节使能信号，从数据存储器读出的数据中选择对应的字节
    wire [`WORD_BUS] data =(cpu_rst_n == `RST_ENABLE) ?`ZERO_WORD:
                           (wb_dre_i == 4'b1111)?{dm[7:0],dm[15:8],dm[23:16],dm[31:24]}:
                           (wb_dre_i == 4'b1000 && wb_unsign_i==1'b0)?{{24{dm[31]}},dm[31:24]}:
                           (wb_dre_i == 4'b1000 && wb_unsign_i==1'b1)?{24'b0,dm[31:24]}:
                           (wb_dre_i == 4'b0100 && wb_unsign_i==1'b0)?{{24{dm[23]}},dm[23:16]}:
                           (wb_dre_i == 4'b0100 && wb_unsign_i==1'b1)?{24'b0,dm[23:16]}:
                           (wb_dre_i == 4'b0010 && wb_unsign_i==1'b0)?{{24{dm[15]}},dm[15:8]}:
                           (wb_dre_i == 4'b0010 && wb_unsign_i==1'b1)?{24'b0,dm[15:8]}:
                           (wb_dre_i == 4'b0001 && wb_unsign_i==1'b0)?{{24{dm[7]}},dm[7:0]}:
                           (wb_dre_i == 4'b0001 && wb_unsign_i==1'b1)?{24'b0,dm[7:0]}:
                           (wb_dre_i == 4'b1100 && wb_unsign_i==1'b0)?{{16{dm[23]}},dm[23:16],dm[31:24]}:
                           (wb_dre_i == 4'b1100 && wb_unsign_i==1'b1)?{16'b0,dm[23:16],dm[31:24]}:
                           (wb_dre_i == 4'b0011 && wb_unsign_i==1'b0)?{{16{dm[7]}},dm[7:0],dm[15:8]}:
                           (wb_dre_i == 4'b0011 && wb_unsign_i==1'b1)?{16'b0,dm[7:0],dm[15:8]}:`ZERO_WORD;

    //根据存储器到寄存器使能信号mreg，选择最终待写入通用寄存器的数据
    assign wb_wd_o = (cpu_rst_n == `RST_ENABLE ) ? `ZERO_WORD : 
                     (wb_mreg_i == `MREG_ENABLE)?data:wb_dreg_i;
    
endmodule
