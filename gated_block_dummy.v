`timescale 1ns / 1ps

module gated_block_dummy (
    input wire clk,
    input wire rst_n,
    input wire save_state,
    output reg ack_from_block
);
    
    reg [1:0] save_state_dly;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            save_state_dly <= 2'b0;
            ack_from_block <= 1'b0;
        end else begin
            save_state_dly[0] <= save_state;
            save_state_dly[1] <= save_state_dly[0];
            
            if (save_state_dly[1] == 1'b1) begin
                ack_from_block <= 1'b1;
            end else begin
                ack_from_block <= 1'b0;
            end
        end
    end
endmodule