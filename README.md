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

## 6. Project Usefulness & Strengths

#### Usefulness
* **Energy Efficiency:** This is a critical technique for extending battery life in mobile devices (phones, laptops, wearables) and reducing energy costs and heat in large data centers.
* **Industry Relevance:** Power gating is a standard, non-negotiable part of virtually all modern complex System-on-Chip (SoC) designs. Understanding its control logic is a highly valuable skill in the semiconductor industry.

#### Strengths of this Project
* **Correct Logic Implementation:** The project successfully models and verifies the strict, sequential logic required for safe power gating, preventing common issues like data corruption.
* **Metrics-Driven Verification:** Instead of just visually checking a waveform, the testbench calculates a quantitative result (**63.22% leakage energy saved**). This provides a concrete measure of the controller's effectiveness under the simulated workload.
* **Modular Design:** The project is well-structured with a clear separation between the controller, the block-under-control, and the verification environment, which is excellent engineering practice.

## 6. Shortcomings & Limitations

This project is a **digital, behavioral-level simulation**. While it proves the control logic is correct, it has several important limitations.

* **No Physical Power Measurement:** The most significant shortcoming is that **Icarus Verilog cannot measure real physical power (in Watts)**. Leakage is an analog, physical phenomenon dependent on transistor physics and voltage. The "LPU-Cycles" metric is a logical proxy used to demonstrate the *duration* of the power-off state, not the actual energy saved.
* **Abstracted Hardware:** The design does not include the physical implementation of key components. The actual header/footer power switches, isolation cells, and state retention registers (SRRs) are only represented by the control signals that would drive them. A full implementation would require transistor-level design.
* **Simplified Models:** The `gated_block_dummy` is not a real functional block. It only models the timing of the handshake acknowledgment. A real-world block would have complex internal states and dependencies.
* **Limited Test Scenario:** The testbench verifies one specific "happy path" workload. A production-level verification would require hundreds of tests with randomized timings, different active/idle periods, and error injection to ensure the controller is robust under all possible conditions.
