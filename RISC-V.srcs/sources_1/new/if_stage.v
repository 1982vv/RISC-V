`include "defines.v"

module if_stage (
    input 	wire 					cpu_clk_50M,
    input 	wire 					cpu_rst_n,
    
    input wire [`STALL_BUS] stall,
    
    output  wire                     ice,
    output 	reg  [`INST_ADDR_BUS] 	pc,
    output 	wire [`INST_ADDR_BUS]	iaddr,
    
    //跳转指令
    input   wire [`INST_ADDR_BUS]   jump_addr_1,
    input   wire [`INST_ADDR_BUS]   jump_addr_2,
    input   wire [`INST_ADDR_BUS]   jump_addr_3,
    input   wire [`JTSEL_BUS    ]   jtsel,
    output  wire [`INST_ADDR_BUS]   pc_plus_4,
    input   wire       clear,
    input   wire [`INST_ADDR_BUS] pc_next_i
    );
    
    wire [`INST_ADDR_BUS] pc_next; 
    reg ce;
    //跳转指令
    assign pc_plus_4=(cpu_rst_n==`RST_ENABLE)?`PC_INIT:pc+4;

    assign pc_next = (clear==1'b1)? pc_next_i:
                     (jtsel == 2'b00)? pc_plus_4:   // 计算下一条指令的地址
                     (jtsel == 2'b01)?jump_addr_1:
                     (jtsel == 2'b10)?jump_addr_3:
                     (jtsel == 2'b11)?jump_addr_2:`PC_INIT;

    always @(posedge cpu_clk_50M) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            ce <= `CHIP_DISABLE;              // 复位的时候指令存储器禁用  
        end else begin
            ce <= `CHIP_ENABLE;               // 复位结束后，指令存储器使能
        end
    end
 
    assign ice = (stall[1] == 1'b1)?1'b0:
                 (clear==1'b1)?1'b0:ce;
    
    always @(posedge cpu_clk_50M) begin
        if (ce == `CHIP_DISABLE)
            pc <= `PC_INIT;                   // 指令存储器禁用的时候，PC保持初始值（设置为0x00000000）
        else if(stall[0] == `NOSTOP )begin
            pc <= pc_next;                    // 指令存储器使能后，PC值每时钟周期加4     
        end
    end

    assign iaddr = (ice == `CHIP_DISABLE) ? `PC_INIT : pc;    // 获得访问指令存储器的地址

endmodule