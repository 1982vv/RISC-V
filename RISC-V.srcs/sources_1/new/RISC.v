`include "defines.v"

module RISC(
    input  wire                  cpu_clk_50M,
    input  wire                  cpu_rst_n,

    // 与指令寄存器IM相连接的端口
    output wire [`INST_ADDR_BUS] iaddr,
    output wire                  ice,
    input  wire [`INST_BUS]      inst,

    // 与数据存储器DM相连接的端口
    output wire                  dce,
    output wire [`INST_ADDR_BUS] daddr,
    output wire [`BSEL_BUS]      we,
    output wire [`INST_BUS]      din,
    input  wire [`INST_BUS]      dm  
    );
    //连接取指阶段与取指/译码寄存器的信号
    wire [`WORD_BUS      ] pc;
    wire [`INST_ADDR_BUS]   pc_plus_4;

    // 连接IF/ID模块与译码阶段ID模块的变量 
    wire [`WORD_BUS      ] id_pc_i;
    wire [`INST_ADDR_BUS]   id_pc_plus_4;
        
    // 连接译码阶段ID模块与通用寄存器Regfile模块的变量 
    wire                    re1;
    wire [`REG_ADDR_BUS  ] ra1;
    wire [`REG_BUS       ] rd1;
    wire                    re2;
    wire [`REG_ADDR_BUS  ] ra2;
    wire [`REG_BUS       ] rd2;
    
    //连接译码阶段与译码/执行寄存器的信号
    wire [`ALUOP_BUS     ] id_aluop_o;
    wire [`ALUTYPE_BUS   ] id_alutype_o;
    wire [`REG_BUS          ] id_src1_o;
    wire [`REG_BUS          ] id_src2_o;
    wire                    id_wreg_o;
    wire [`REG_ADDR_BUS  ] id_wa_o;
    wire                    id_mreg_o;
    wire [`REG_BUS       ] id_din_o;
    wire [`INST_ADDR_BUS]    jump_addr_1;
    wire [`INST_ADDR_BUS]    jump_addr_2;
    wire [`INST_ADDR_BUS]    jump_addr_3;
    wire [`JTSEL_BUS    ]    jtsel;
    wire [`INST_ADDR_BUS]    ret_addr;
    
    //连接译码/执行寄存器与执行阶段的信号
    wire [`ALUOP_BUS     ] exe_aluop_i;
    wire [`ALUTYPE_BUS   ] exe_alutype_i;
    wire [`REG_BUS          ] exe_src1_i;
    wire [`REG_BUS          ] exe_src2_i;
    wire                    exe_wreg_i;
    wire [`REG_ADDR_BUS  ] exe_wa_i;
    wire                   exe_mreg_i;
    wire [`REG_BUS       ] exe_din_i;
    wire [`REG_BUS       ] exe_ret_addr;


    //连接执行阶段与执行/访存寄存器的信号
    wire [`ALUOP_BUS     ] exe_aluop_o;
    wire                    exe_wreg_o;
    wire [`REG_ADDR_BUS  ] exe_wa_o;
    wire [`REG_BUS          ] exe_wd_o;
    wire                   exe_mreg_o;
    wire [`REG_BUS       ] exe_din_o;  
     
    //连接执行/访存寄存器与访存阶段的信号
    wire [`ALUOP_BUS     ] mem_aluop_i;
    wire                    mem_wreg_i;
    wire [`REG_ADDR_BUS  ] mem_wa_i;
    wire [`REG_BUS          ] mem_wd_i;
    wire                   mem_mreg_i;
    wire [`REG_BUS       ] mem_din_i;
    
    //连接访存阶段与访存/写回寄存器的信号
    wire                    mem_wreg_o;
    wire [`REG_ADDR_BUS  ] mem_wa_o;
    wire [`REG_BUS          ] mem_dreg_o;
    wire                   mem_mreg_o;
    wire [`REG_BUS       ] mem_dre_o;
    wire                   unsign1;
    
    //连接访存/写回寄存器与写回阶段的信号
    wire                    wb_wreg_i;
    wire [`REG_ADDR_BUS  ] wb_wa_i;
    wire [`REG_BUS       ] wb_dreg_i;
    wire                   wb_mreg_i;
    wire [`REG_BUS       ] wb_dre_i;
    wire                   unsign2;
    
    //连接写回阶段与通用寄存器堆的信号
    wire                    wb_wreg_o;
    wire [`REG_ADDR_BUS  ] wb_wa_o;
    wire [`REG_BUS       ] wb_wd_o;

    //暂停控制模块信号
    wire      stallreq_id;
    wire      stallreq_exe;
    wire [`STALL_BUS ] stall; 
    
    //流水线清空
    wire      id_clear;
    wire [`INST_ADDR_BUS] id_pc_next;
    wire      clear;
    wire [`INST_ADDR_BUS] pc_next;

    if_stage if_stage0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .pc(pc), .ice(ice), .iaddr(iaddr),.jump_addr_1(jump_addr_1),
            .jump_addr_2(jump_addr_2),.jump_addr_3(jump_addr_3),
            .jtsel(jtsel),.pc_plus_4(pc_plus_4),.stall(stall),.clear(clear),.pc_next_i(pc_next)
    );
    
    ifid_reg ifid_reg0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .if_pc(pc), .id_pc(id_pc_i),.if_pc_plus_4(pc_plus_4),
            .id_pc_plus_4(id_pc_plus_4),.stall(stall)
    );

    id_stage id_stage0(.cpu_rst_n(cpu_rst_n), .id_pc_i(id_pc_i), 
        .id_inst_i(inst),
        .rd1(rd1), .rd2(rd2),
        .rreg1(re1), .rreg2(re2),       
        .ra1(ra1), .ra2(ra2), 
        .id_aluop_o(id_aluop_o), .id_alutype_o(id_alutype_o),
        .id_src1_o(id_src1_o), .id_src2_o(id_src2_o),
        .id_wa_o(id_wa_o), .id_wreg_o(id_wreg_o),
        .id_mreg_o(id_mreg_o),.id_din_o(id_din_o),
        .exe2id_wreg(exe_wreg_o),.exe2id_wa(exe_wa_o),
        .exe2id_wd(exe_wd_o),.mem2id_wreg(mem_wreg_o),
        .mem2id_wa(mem_wa_o),.mem2id_wd(mem_dreg_o),
        .pc_plus_4(id_pc_plus_4),.ret_addr(ret_addr),
        .jump_addr_1(jump_addr_1),.jump_addr_2(jump_addr_2),
        .jump_addr_3(jump_addr_3),.jtsel(jtsel),.exe2id_mreg(exe_mreg_o),
        .mem2id_mreg(mem_mreg_o),.stallreq_id(stallreq_id),.clear(id_clear),.pc_next_o(id_pc_next)
    );
    
    regfile regfile0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .we(wb_wreg_o), .wa(wb_wa_o), .wd(wb_wd_o),
        .re1(re1), .ra1(ra1), .rd1(rd1),
        .re2(re2), .ra2(ra2), .rd2(rd2)
    );
    
    idexe_reg idexe_reg0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n), 
        .id_alutype(id_alutype_o), .id_aluop(id_aluop_o),
        .id_src1(id_src1_o), .id_src2(id_src2_o),
        .id_wa(id_wa_o), .id_wreg(id_wreg_o),
        .id_mreg(id_mreg_o),.id_din(id_din_o),
        .exe_alutype(exe_alutype_i), .exe_aluop(exe_aluop_i),
        .exe_src1(exe_src1_i), .exe_src2(exe_src2_i), 
        .exe_wa(exe_wa_i), .exe_wreg(exe_wreg_i),
        .exe_mreg(exe_mreg_i),.exe_din(exe_din_i),
        .id_ret_addr(ret_addr),.exe_ret_addr(exe_ret_addr),.stall(stall)
    );
    
    exe_stage exe_stage0(.cpu_rst_n(cpu_rst_n),.cpu_clk_50M(cpu_clk_50M),
        .exe_alutype_i(exe_alutype_i), .exe_aluop_i(exe_aluop_i),
        .exe_src1_i(exe_src1_i), .exe_src2_i(exe_src2_i),
        .exe_wa_i(exe_wa_i), .exe_wreg_i(exe_wreg_i),
        .exe_mreg_i(exe_mreg_i),.exe_din_i(exe_din_i),
        .exe_aluop_o(exe_aluop_o),
        .exe_wa_o(exe_wa_o), .exe_wreg_o(exe_wreg_o), .exe_wd_o(exe_wd_o),
        .exe_mreg_o(exe_mreg_o),.exe_din_o(exe_din_o),
        .ret_addr(exe_ret_addr),.stallreq_exe(stallreq_exe)
    );
        
    exemem_reg exemem_reg0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .exe_aluop(exe_aluop_o),
        .exe_wa(exe_wa_o), .exe_wreg(exe_wreg_o), .exe_wd(exe_wd_o),
        .exe_mreg(exe_mreg_o),.exe_din(exe_din_o),
        .mem_aluop(mem_aluop_i),
        .mem_wa(mem_wa_i), .mem_wreg(mem_wreg_i), .mem_wd(mem_wd_i),
        .mem_mreg(mem_mreg_i),.mem_din(mem_din_i),.stall(stall)
    );

    mem_stage mem_stage0(.cpu_rst_n(cpu_rst_n), .mem_aluop_i(mem_aluop_i),
        .mem_wa_i(mem_wa_i), .mem_wreg_i(mem_wreg_i), .mem_wd_i(mem_wd_i),
        .mem_mreg_i(mem_mreg_i),.mem_din_i(mem_din_i),
        .mem_wa_o(mem_wa_o), .mem_wreg_o(mem_wreg_o), .mem_dreg_o(mem_dreg_o),.unsign(unsign1),
        .mem_mreg_o(mem_mreg_o),.dre(mem_dre_o),.dce(dce),.daddr(daddr),.we(we),.din(din)
    );
        
    memwb_reg memwb_reg0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .mem_wa(mem_wa_o), .mem_wreg(mem_wreg_o), .mem_dreg(mem_dreg_o),
        .mem_mreg(mem_mreg_o), .mem_dre(mem_dre_o),
        .wb_wa(wb_wa_i), .wb_wreg(wb_wreg_i), .wb_dreg(wb_dreg_i),
        .wb_mreg(wb_mreg_i),.wb_dre(wb_dre_i),.mem_unsign(unsign1),.wb_unsign(unsign2)
    );

    wb_stage wb_stage0(.cpu_rst_n(cpu_rst_n),
        .wb_wa_i(wb_wa_i), .wb_wreg_i(wb_wreg_i), .wb_dreg_i(wb_dreg_i), 
        .wb_mreg_i(wb_mreg_i),.wb_dre_i(wb_dre_i),
        .wb_wa_o(wb_wa_o), .wb_wreg_o(wb_wreg_o), .wb_wd_o(wb_wd_o),
        .dm(dm),.wb_unsign_i(unsign2)
    );

    scu scu0(
        .cpu_rst_n(cpu_rst_n),.stallreq_id(stallreq_id),
        .stallreq_exe(stallreq_exe),.stall(stall)
    );
    clear clear0(
        .id_clear(id_clear),.pc_next(id_pc_next),.clear(clear),.pc_next_o(pc_next)
    );
endmodule
