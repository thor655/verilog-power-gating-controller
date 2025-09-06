////////////////////////////////////////////////////////////////////////////////
//
// Module: power_gating_controller.v (Stable Version)
//
// Description: The simple, stable FSM controller. This logic is already
//              robust against redundant power-on requests by design.
//
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module power_gating_controller (
    // Control Inputs
    input wire clk,
    input wire rst_n,
    input wire power_on_req,
    input wire power_off_req,
    input wire ack_from_block,

    // Outputs to control the power-gated domain
    output reg isolate_en,
    output reg save_state,
    output reg restore_state,
    output reg power_switch_en,

    // Acknowledgment outputs to the system
    output reg power_on_ack,
    output reg power_off_ack
);

    // FSM State Definitions
    localparam [2:0] IDLE_OFF      = 3'b000;
    localparam [2:0] PWR_UP_SEQ    = 3'b001;
    localparam [2:0] WAIT_STABLE   = 3'b010;
    localparam [2:0] IDLE_ON       = 3'b011;
    localparam [2:0] PWR_DN_SEQ_1  = 3'b100;
    localparam [2:0] PWR_DN_SEQ_2  = 3'b101;
    localparam [2:0] PWR_DN_SEQ_3  = 3'b110;

    // State registers
    reg [2:0] current_state, next_state;
    reg [3:0] stable_counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state <= IDLE_OFF;
        else current_state <= next_state;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) stable_counter <= 0;
        else if (current_state == PWR_UP_SEQ) stable_counter <= 4'd10;
        else if (current_state == WAIT_STABLE && stable_counter > 0) stable_counter <= stable_counter - 1;
    end

    always @(*) begin
        next_state      = current_state;
        isolate_en      = 1'b1;
        save_state      = 1'b0;
        restore_state   = 1'b0;
        power_switch_en = 1'b1;
        power_on_ack    = 1'b0;
        power_off_ack   = 1'b0;

        case (current_state)
            IDLE_OFF: begin
                power_switch_en = 1'b0;
                if (power_on_req) next_state = PWR_UP_SEQ;
            end
            PWR_UP_SEQ: next_state = WAIT_STABLE;
            WAIT_STABLE: if (stable_counter == 0) begin
                restore_state = 1'b1;
                next_state = IDLE_ON;
            end
            IDLE_ON: begin
                isolate_en = 1'b0;
                power_on_ack = 1'b1;
                // NOTE: This logic correctly ignores power_on_req
                // and only acts on power_off_req.
                if (power_off_req) next_state = PWR_DN_SEQ_1;
            end
            PWR_DN_SEQ_1: next_state = PWR_DN_SEQ_2;
            PWR_DN_SEQ_2: begin
                save_state = 1'b1;
                if (ack_from_block) next_state = PWR_DN_SEQ_3;
            end
            PWR_DN_SEQ_3: begin
                power_switch_en = 1'b0;
                power_off_ack = 1'b1;
                next_state = IDLE_OFF;
            end
            default: next_state = IDLE_OFF;
        endcase
    end
endmodule

