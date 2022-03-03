`timescale 1ns / 1ps

module clear(
    input wire        id_clear,
    input wire [`INST_ADDR_BUS] pc_next,
    output wire       clear,
    output wire [`INST_ADDR_BUS] pc_next_o
    );
    assign clear=(id_clear)?1'd1:1'd0;
    assign pc_next_o=pc_next;
    
endmodule
