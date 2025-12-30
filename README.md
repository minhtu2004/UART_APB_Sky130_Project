# UART-APB Controller: Full Digital Design Flow (iCE40 FPGA & Sky130 ASIC)

## Project Overview
This repository contains the complete design and implementation of a **UART Controller** with an **APB (Advanced Peripheral Bus) Wrapper**. The project demonstrates a professional dual-target silicon design flow:
1. **FPGA Prototyping:** Validated on **Lattice iCE40-HX8K** for logic functionality.
2. **ASIC Implementation:** Hardened using the **OpenLane** flow on **SkyWater 130nm** Open Source PDK.

## Architecture
The system integrates a UART Core (TX/RX), an AXI-Stream compatible FIFO, and an APB interface for seamless SoC integration.

![Block Diagram](./docs/block_diagram.png)
*Figure 1: RTL Block Diagram & Interconnect*

## ASIC Sign-off Results (SkyWater 130nm)
The design successfully passed all physical verification and timing sign-off stages:
- **Die Area:** 0.0533 mm² ($225.3 \times 223.6 \mu m$)
- **Gate Count:** 1,569 logic gates (Total 5,648 cells including physical cells)
- **Power Consumption:** **4.48 mW** (@ 100MHz, Typical Corner)
- **Timing:** Setup Slack MET (+8.14 ns)
- **Physical Sign-off:** **100% Clean DRC, LVS, and Antenna checks**.

![Final Layout](./docs/layout_preview.png)
*Figure 2: Final Silicon Layout (GDSII) in KLayout*

## FPGA Verification (iCE40-HX8K)
- **Max Frequency:** **85.30 MHz**
- **Verification Status:** Passed timing analysis and logic verification using the IceStorm toolchain.

## Repository Structure
- `/rtl`: Verilog source code (Core, FIFO, Wrapper).
- `/verification`: Testbenches for logic simulation.
- `/openlane`: Design configuration (`config.json`) and final GDSII.
- `/fpga`: iCE40 placement, routing, and timing reports.
- `/docs`: Detailed sign-off reports (Power, Timing, Area, DRC, LVS, Antenna).

## Tools Used
- **Synthesis:** Yosys
- **Place & Route:** OpenROAD / nextpnr-ice40
- **Sign-off:** Magic (DRC), Netgen (LVS), OpenSTA (Timing)
- **Visualization:** KLayout
