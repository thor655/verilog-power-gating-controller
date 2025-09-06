`timescale 1ns / 1ps

module tb_power_gating;

    reg clk;
    reg rst_n;
    reg power_on_req;
    reg power_off_req;
    reg ack_from_block_tb;

    wire isolate_en;
    wire save_state;
    wire restore_state;
    wire power_switch_en;
    wire power_on_ack;
    wire power_off_ack;

    integer total_simulation_cycles = 0;
    integer power_on_cycles = 0;
    real savings_percentage;

    top uut (
        .clk(clk), .rst_n(rst_n), .power_on_req(power_on_req),
        .power_off_req(power_off_req), .ack_from_block_tb(ack_from_block_tb),
        .isolate_en(isolate_en), .save_state(save_state),
        .restore_state(restore_state), .power_switch_en(power_switch_en),
        .power_on_ack(power_on_ack), .power_off_ack(power_off_ack)
    );

    initial forever #5 clk = ~clk;

    always @(posedge clk) begin
        if(rst_n) begin
            total_simulation_cycles = total_simulation_cycles + 1;
            if (power_switch_en) begin
                power_on_cycles = power_on_cycles + 1;
            end
        end
    end

    initial begin
        $dumpfile("power_gating_metrics.vcd");
        $dumpvars(0, tb_power_gating);
        clk = 0;
        rst_n = 0;
        power_on_req = 0;
        power_off_req = 0;
        ack_from_block_tb = 0;
        #20;
        rst_n = 1;
        $display("[%0t ns] Reset released. System is in POWER_OFF state.", $time);

        #100;
        $display("[%0t ns] Asserting power_on_req.", $time);
        power_on_req = 1;
        @(posedge power_on_ack);
        power_on_req = 0;
        $display("[%0t ns] Power-up sequence complete (power_on_ack received).", $time);

        #500;
        $display("[%0t ns] Asserting power_off_req.", $time);
        power_off_req = 1;
        @(posedge save_state);
        #10 ack_from_block_tb = 1;
        @(posedge power_off_ack);
        power_off_req = 0;
        ack_from_block_tb = 0;
        $display("[%0t ns] Power-down sequence complete (power_off_ack received).", $time);
        
        #1000;
        
        $display("\n----------------- SIMULATION COMPLETE -----------------\n");
        
        // ============================ FIXED LINE ============================
        // This line now performs the calculation in a way that is compatible
        // with standard Verilog, avoiding the unsupported syntax.
        savings_percentage = (1.0 - ((power_on_cycles * 1.0) / (total_simulation_cycles * 1.0))) * 100.0;
        // ====================================================================

        $display("           PERFORMANCE METRICS");
        $display("--------------------------------------------------");
        $display("Total Simulation Duration   : %0d clock cycles", total_simulation_cycles);
        $display("Cycles in Power-ON State    : %0d clock cycles", power_on_cycles);
        $display("");
        $display("Leakage without Power Gating: %0d LPU-Cycles", total_simulation_cycles);
        $display("Leakage with Power Gating   : %0d LPU-Cycles", power_on_cycles);
        $display("");
        $display("--> Leakage Energy Saved    : %0.2f %%", savings_percentage);
        $display("--------------------------------------------------");
        $finish;
    end
endmodule

