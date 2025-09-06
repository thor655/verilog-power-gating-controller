`timescale 1ns / 1ps

module tb_power_gating;

    // DUT Interface
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

    // Metrics calculation
    integer total_simulation_cycles = 0;
    integer power_on_cycles = 0;
    real savings_percentage;

    // DUT Instantiation
    top uut (
        .clk(clk), .rst_n(rst_n), .power_on_req(power_on_req),
        .power_off_req(power_off_req), .ack_from_block_tb(ack_from_block_tb),
        .isolate_en(isolate_en), .save_state(save_state),
        .restore_state(restore_state), .power_switch_en(power_switch_en),
        .power_on_ack(power_on_ack), .power_off_ack(power_off_ack)
    );

    // Clock Generation
    initial forever #5 clk = ~clk;

    // Metrics Counter
    always @(posedge clk) begin
        if(rst_n) begin
            total_simulation_cycles = total_simulation_cycles + 1;
            if (power_switch_en) begin
                power_on_cycles = power_on_cycles + 1;
            end
        end
    end

    // Main Test Sequence
    initial begin
        $dumpfile("power_gating_metrics.vcd");
        $dumpvars(0, tb_power_gating);
        clk = 0; rst_n = 0; power_on_req = 0; power_off_req = 0; ack_from_block_tb = 0;
        #20; rst_n = 1;
        $display("[%0t ns] Reset released. System is in POWER_OFF state.", $time);

        // --- PHASE 1: Happy Path Operation ---
        #100;
        $display("\n--- PHASE 1: Running Happy Path Test ---");
        $display("[%0t ns] Asserting power_on_req.", $time);
        power_on_req = 1;
        @(posedge power_on_ack);
        power_on_req = 0;
        $display("[%0t ns] Power-up sequence complete (power_on_ack received).", $time);

        // --- PHASE 2: Redundant Request Robustness Check ---
        #50;
        $display("\n--- PHASE 2: Running Redundant Request Test ---");
        $display("[%0t ns] Sending redundant power_on_req while already ON...", $time);
        power_on_req = 1;
        #20; // Hold the request for a few cycles
        power_on_req = 0;

        // SELF-CHECK: The state should NOT have changed from IDLE_ON (3'b011)
        if (uut.pgc_inst.current_state === 3'b011) begin
            $display("PASS: Controller correctly ignored the redundant request.");
        end else begin
            $error("FAIL: Controller state was disturbed by the redundant request!");
        end
        
        // --- PHASE 3: Continue Happy Path to Power Down ---
        #430; // Remainder of the active period
        $display("\n--- PHASE 3: Continuing to Power-Down ---");
        $display("[%0t ns] Asserting power_off_req.", $time);
        power_off_req = 1;
        @(posedge save_state);
        #10 ack_from_block_tb = 1;
        @(posedge power_off_ack);
        power_off_req = 0;
        ack_from_block_tb = 0;
        $display("[%0t ns] Power-down sequence complete (power_off_ack received).", $time);
        
        #1000;
        
        // --- FINAL REPORT ---
        $display("\n----------------- SIMULATION COMPLETE -----------------\n");
        savings_percentage = (1.0 - ($itor(power_on_cycles) / $itor(total_simulation_cycles))) * 100.0;
        $display("           PERFORMANCE METRICS");
        $display("--------------------------------------------------");
        $display("Total Simulation Duration   : %0d clock cycles", total_simulation_cycles);
        $display("Cycles in Power-ON State    : %0d clock cycles", power_on_cycles);
        $display("");
        $display("--> Leakage Energy Saved    : %0.2f %%", savings_percentage);
        $display("--------------------------------------------------");
        $finish;
    end
endmodule

