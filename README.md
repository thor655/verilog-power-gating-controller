# VLSI Power Gating Controller for Leakage Power Reduction

## 1. Project Overview

This project presents the design and verification of a digital controller for **power gating**, a fundamental technique used in modern VLSI (Very-Large-Scale Integration) chip design to reduce static leakage power. When a block of logic on a chip is idle, it still consumes power due to transistor leakage. This controller safely disconnects the idle block from the power supply, effectively eliminating this leakage and saving significant energy.

The entire design is implemented in Verilog and verified using the open-source Icarus Verilog simulator.

## 2. Project Goal

The primary goal of this project is to create a robust Finite State Machine (FSM) that correctly orchestrates the complex sequence of operations required to power a logic block down and back up without causing data corruption or electrical issues on the chip.

The key sequence of operations managed by the controller is:
1.  **Power-Down:** Isolate outputs -> Save state -> Cut power.
2.  **Power-Up:** Restore power -> Stabilize -> Restore state -> De-isolate.

## 3. Files in This Project

* `power_gating_controller.v`: The core of the project. Contains the FSM logic that generates all control signals.
* `gated_block_dummy.v`: A simple placeholder module that mimics the behavior of the logic block being controlled, specifically its acknowledgment handshake.
* `top.v`: The top-level structural file that connects the controller and the dummy block into a single testable unit.
* `tb_power_gating.v`: A comprehensive testbench that drives the simulation, provides stimulus, and calculates the final power-saving metrics.

## 4. How to Run

1.  **Prerequisites:** Icarus Verilog (`iverilog`) and a waveform viewer like GTKWave must be installed.
2.  **Compile:** Place all four `.v` files in a directory and run the following command in your terminal:
    ```bash
    iverilog -o pg_sim top.v power_gating_controller.v gated_block_dummy.v tb_power_gating.v
    ```
3.  **Simulate:** Execute the compiled simulation:
    ```bash
    vvp pg_sim
    ```

## 5. Simulation Results

The simulation will run a complete power-on, active, and power-down cycle. The testbench will print a final report to the console, quantifying the effectiveness of the controller.

**Expected Output:**
