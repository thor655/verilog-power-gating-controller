////////////////////////////////////////////////////////////////////////////////
//
// Module: power_gating_controller.v
//
// Description: A Finite State Machine (FSM) to control the power-up and
//              power-down sequence of a logic block.
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
    localparam [2:0] PWR_DN_SEQ_1  = 3'b100; // Isolate
    localparam [2:0] PWR_DN_SEQ_2  = 3'b101; // Save state, wait for ack
    localparam [2:0] PWR_DN_SEQ_3  = 3'b110; // Power off

    // State registers
    reg [2:0] current_state, next_state;

    // A small counter to wait for virtual power rail to stabilize
    reg [3:0] stable_counter;

    // Sequential Logic for State Transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE_OFF;
        end else begin
            current_state <= next_state;
        end
    end

    // Sequential logic for the stabilization counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stable_counter <= 0;
        end else if (current_state == PWR_UP_SEQ) begin
             // Load the counter when we start the power-up sequence
            stable_counter <= 4'd10;
        end else if (current_state == WAIT_STABLE && stable_counter > 0) begin
            stable_counter <= stable_counter - 1;
        end
    end

    // Combinational Logic for Next State and Outputs
    always @(*) begin
        // Set default values for all outputs to avoid latches
        next_state      = current_state;
        isolate_en      = 1'b1; // Default to isolated
        save_state      = 1'b0;
        restore_state   = 1'b0;
        power_switch_en = 1'b1;
        power_on_ack    = 1'b0;
        power_off_ack   = 1'b0;

        case (current_state)
            IDLE_OFF: begin
                power_switch_en = 1'b0;
                if (power_on_req) begin
                    next_state = PWR_UP_SEQ;
                end
            end

            PWR_UP_SEQ: begin
                // This state simply transitions to the next, starting the counter
                next_state = WAIT_STABLE;
            end
            
            WAIT_STABLE: begin
                // Stay here until the power rail is stable
                if (stable_counter == 0) begin
                    restore_state = 1'b1; // Restore flip-flop states
                    next_state = IDLE_ON;
                end
            end

            IDLE_ON: begin
                isolate_en = 1'b0; // System is active
                power_on_ack = 1'b1; // Signal that block is ready to use
                if (power_off_req) begin
                    next_state = PWR_DN_SEQ_1;
                end
            end

            PWR_DN_SEQ_1: begin
                // Step 1: Isolate the block. (isolate_en is 1 by default)
                next_state = PWR_DN_SEQ_2;
            end
            
            PWR_DN_SEQ_2: begin
                save_state = 1'b1; // Step 2: Instruct registers to save state
                // Wait for the block to acknowledge it's ready for shutdown
                if (ack_from_block) begin
                    next_state = PWR_DN_SEQ_3;
                end
            end
            
            PWR_DN_SEQ_3: begin
                power_switch_en = 1'b0; // Step 3: Cut the power
                power_off_ack = 1'b1; // Signal that shutdown is complete
                next_state = IDLE_OFF;
            end
            
            default: begin
                next_state = IDLE_OFF;
            end
        endcase
    end
endmodule