`timescale 1ns / 1ps

module top (
    input wire clk,
    input wire rst_n,
    input wire power_on_req,
    input wire power_off_req,
    input wire ack_from_block_tb,
    output wire isolate_en,
    output wire save_state,
    output wire restore_state,
    output wire power_switch_en,
    output wire power_on_ack,
    output wire power_off_ack
);

    wire ack_from_block_dummy;

    power_gating_controller pgc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .power_on_req(power_on_req),
        .power_off_req(power_off_req),
        .ack_from_block(ack_from_block_tb),
        .isolate_en(isolate_en),
        .save_state(save_state),
        .restore_state(restore_state),
        .power_switch_en(power_switch_en),
        .power_on_ack(power_on_ack),
        .power_off_ack(power_off_ack)
    );

    gated_block_dummy dummy_inst (
        .clk(clk),
        .rst_n(rst_n),
        .save_state(save_state),
        .ack_from_block(ack_from_block_dummy)
    );
endmodule