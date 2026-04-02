# Project Main

This repository contains a system-on-chip project split across FPGA-only design files, an HPS+FPGA integrated build, and a separate shared Verilog source tree.

## Project Layout

- `fpga_Project/`: FPGA-only Quartus project assets, generated build outputs, and simulation support files.
- `hps_fpga_Project/`: Combined HPS and FPGA project, including the SoC system, generated submodules, HPS software, and run logs.
- `Verilog_srcs/`: Standalone Verilog source directory for reusable design modules and top-level HDL sources.

## Start Here

- HPS application code: `hps_fpga_Project/hps_code/`
- HPS run and debug logs: `hps_fpga_Project/hps_logs/`
- SoC synthesis submodules referenced in the current workflow:
  - `hps_fpga_Project/soc_system/synthesis/submodules/cluster_ctrl.v`
  - `hps_fpga_Project/soc_system/synthesis/submodules/cluster_top.v`
  - `hps_fpga_Project/soc_system/synthesis/submodules/eric_ip2.v`
  - `hps_fpga_Project/soc_system/synthesis/submodules/mac_2x2.v`
- Current HPS-side driver entry point:
  - `hps_fpga_Project/hps_code/main.c`

## Notes

The `hps_fpga_Project` tree contains both generated SoC integration artifacts and handwritten HPS/RTL code. If you are tracing the cluster data path, start with `main.c`, then follow the APB interface in `eric_ip2.v`, the cluster wrapper in `cluster_top.v`, and the state machine in `cluster_ctrl.v`.